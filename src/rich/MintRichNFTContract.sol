// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721AQueryableUpgradeable.sol";
import "./MintRichCommonStorage.sol";
import "../libs/MintRichPriceLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import 'lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol';
import 'lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol';

contract MintRichNFTContract is ERC721AQueryableUpgradeable, MintRichCommonStorage, ReentrancyGuardUpgradeable {

    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    event SaleClosed(address indexed collection);

    event BuyItems(address indexed buyer, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);
    event SellItems(address indexed seller, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);

    event ClaimRewards(address indexed recipient, uint256 claimedAmount);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _factoryAddress) MintRichCommonStorage(_factoryAddress) {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bytes calldata information
    ) public initializerERC721A initializer {
        require(msg.sender == FACTORY, "Can only be initialized by factory");
        __ERC721A_init(name_, symbol_);
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();

        initInformation(information);
        salePhase = SalePhase.PUBLIC;
        DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function initInformation(bytes calldata information) internal {
        
    }

    modifier checkSalePhase() {
        require(salePhase == SalePhase.PUBLIC, "Public sale ended");
        _;

        if (activeSupply == MAX_SUPPLY) {
            salePhase = SalePhase.CLOSED;
            emit SaleClosed(address(this));
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function buy(uint256 amount) external payable nonReentrant checkSalePhase {
        require(amount > 0 && activeSupply + amount <= MAX_SUPPLY, "Buy amount exceeds MAX_SUPPLY limit");

        (uint256 prices, uint256 fees) = buyQuota(amount);
        uint256 totalPrices = prices + fees;
        require(totalPrices <= msg.value, "Not enough ETH to buy NFTs");

        buyNFTs(amount);
        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply += amount;

        emit BuyItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        if (msg.value > totalPrices) {
            (bool success, ) = msg.sender.call{value: msg.value - totalPrices}(new bytes(0));
            require(success, 'ETH transfer failed');
        }
    }

    function buyNFTs(uint256 amount) internal {
        address buyer = msg.sender;
        uint256 mintAmount = amount;

        if (!bank.empty()) {
            uint256 withdrawAmount = Math.min(amount, bank.length());
            for (uint256 i = 0; i < withdrawAmount;) {
                transferFrom(address(this), buyer, uint256(bank.popBack()));
                unchecked {
                    ++i;
                }
            }
            mintAmount = amount - withdrawAmount;
        }

        if (mintAmount > 0) {
            _mint(buyer, mintAmount);
        }
    }

    function sell(uint256 amount) external nonReentrant checkSalePhase {
        require(amount > 0 && amount <= balanceOf(msg.sender), "Sell amount exceeds owned amount");
        
        (uint256 prices, uint256 fees) = sellQuota(amount);
        uint256 receivedPrices = prices - fees;

        sellNFTs(amount);
        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply -= amount;

        emit SellItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        (bool success, ) = msg.sender.call{value: receivedPrices}(new bytes(0));
        require(success, 'ETH transfer failed');
    }

    function sellNFTs(uint256 amount) internal {
        address seller = msg.sender;
        uint256[] memory tokenIds = tokensOfOwner(seller);

        for (uint256 i = 0; i < amount;) {
            transferFrom(seller, address(this), tokenIds[i]);
            bank.pushFront(bytes32(tokenIds[i]));
            unchecked {
                ++i;
            }
        }
    }

    function buyQuota(uint256 amount) public view returns (uint256 prices, uint256 fees) {
        prices = MintRichPriceLib.totalTokenPrices(activeSupply, amount);
        fees = (prices * PROTOCOL_FEE) / BASIS_POINTS;
    }
    
    function sellQuota(uint256 amount) public view returns (uint256 prices, uint256 fees) {
        prices = MintRichPriceLib.totalTokenPrices(activeSupply - amount, amount);
        fees = (prices * PROTOCOL_FEE) / BASIS_POINTS;
    }

    function saleBalance() public view returns (uint256 balance) {
        balance = MintRichPriceLib.totalTokenPrices(0, activeSupply);
    }

    function claimRewards(
        uint256 totalRewards,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant {
        address payable recipient = payable(msg.sender);
        require(_verfySigner(recipient, totalRewards, _v, _r, _s) == REWARDS_SIGNER, "Invalid signer");
        require(totalRewards > rewardsClaimed[recipient], "Nothing to claim");

        uint256 toClaim = totalRewards - rewardsClaimed[recipient];
        require(toClaim <= totalFees - claimedFees, "Invalid claim amount");

        claimedFees += toClaim;
        rewardsClaimed[recipient] = totalRewards;
        emit ClaimRewards(recipient, toClaim);

        (bool success, ) = recipient.call{value: toClaim}(new bytes(0));
        require(success, 'ETH transfer failed');
    }

    function tokenURI(uint256 tokenId) public view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "Token not exist");
        return "";
    }

    function _verfySigner(
        address recipient,
        uint256 totalRewards,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (address _signer) {
        _signer = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256("MintRichRewards(address recipient,uint256 totalRewards)"),
                            recipient,
                            totalRewards
                        )
                    )
                )
            ), _v, _r, _s
        );
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("MintRichNFTContract")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

}