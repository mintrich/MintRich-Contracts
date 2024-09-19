// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./MintRichCommonStorage.sol";
import "../libs/MintRichPriceLib.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import 'lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol';
import 'lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol';
import 'lib/ERC721A-Upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';

contract MintRichNFTContract is ERC721AQueryableUpgradeable, MintRichCommonStorage, ReentrancyGuardUpgradeable, ERC721A__IERC721ReceiverUpgradeable {

    using Address for address payable;
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bytes32 packedData,
        bytes calldata information
    ) external initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();

        initInfo(packedData, information);
        salePhase = SalePhase.PUBLIC;
        factoryAddress = msg.sender;
        MINT_RICH_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function initInfo(bytes32 packedData, bytes calldata information) internal {
        imageType = uint8(uint256(packedData));
        require(imageType == IMAGE_TYPE_SINGLE || imageType == IMAGE_TYPE_MULIT, "Invalid imageType");
        baseURI = abi.decode(information, (string));
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

    function amountInBank() external view returns (uint256) {
        return bank.length();
    }

    function owner() external view returns (address) {
        if (salePhase == SalePhase.CLOSED) {
            return address(0);
        }
        return IERC721AUpgradeable(factoryAddress).ownerOf(uint256(uint160(address(this))));
    }

    function buy(uint256 amount) external payable nonReentrant checkSalePhase {
        require(amount > 0 && activeSupply + amount <= MAX_SUPPLY, "Buy amount exceeds MAX_SUPPLY limit");

        (uint256 prices, uint256 fees) = buyQuota(amount);
        uint256 totalPrices = prices + fees;
        require(totalPrices <= msg.value, "Not enough ETH to buy NFTs");

        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply += amount;

        buyNFTs(amount);
        emit BuyItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        if (msg.value > totalPrices) {
            payable(msg.sender).sendValue(msg.value - totalPrices);
        }
    }

    function buyNFTs(uint256 amount) internal {
        address buyer = msg.sender;
        uint256 mintAmount = amount;

        if (!bank.empty()) {
            uint256 withdrawAmount = Math.min(amount, bank.length());
            for (uint256 i = 0; i < withdrawAmount; ++i) {
                uint256 tokenId = uint256(bank.popBack());
                _approve(buyer, tokenId);
                transferFrom(address(this), buyer, tokenId);
            }
            mintAmount = amount - withdrawAmount;
        }

        if (mintAmount > 0) {
            _mint(buyer, mintAmount);
        }
    }

    function sell(uint256 amount, bytes calldata tokenIds) external nonReentrant checkSalePhase {
        require(amount > 0 && amount <= balanceOf(msg.sender), "Sell amount exceeds owned amount");
        require(amount * 2 == tokenIds.length, "TokenIds length don't match");
        
        (uint256 prices, uint256 fees) = sellQuota(amount);
        uint256 receivedPrices = prices - fees;

        totalFees += fees;
        uint256 preSupply = activeSupply;
        activeSupply -= amount;

        sellNFTs(tokenIds);
        emit SellItems(msg.sender, amount, prices, fees, preSupply, activeSupply);

        payable(msg.sender).sendValue(receivedPrices);
    }

    function sellNFTs(bytes memory tokenIds) internal {
        address seller = msg.sender;
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; i = i + 2) {
            uint256 tokenId;
            assembly {
                tokenId := and(mload(add(tokenIds, add(i, 2))), 0xFFFF)
            }
            transferFrom(seller, address(this), tokenId);
            bank.pushFront(bytes32(tokenId));
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

    function processSaleClosed() external nonReentrant {
        require(false, "Process disabled for ERC721A");
        require(msg.sender == MINT_RICH_ADMIN, "Only admin can process");
        require(salePhase == SalePhase.CLOSED, "Sale not closed");

        uint256 totalBalance = saleBalance();
        uint256 share = (totalBalance * MINT_RICH_SHARE_POINTS) / BASIS_POINTS;
        MINT_RICH_RECIPIENT.sendValue(share);

        uint256 bids = (totalBalance * MINT_RICH_BIDS_POINTS) / BASIS_POINTS;
        Address.functionCallWithValue(WETH9, abi.encodeWithSelector(WETH9_DEPOSIT_SELECTOR), bids);
        IERC20(WETH9).approve(MINTSWAP_NFT_MARKETPLACE, bids);

        Address.functionCall(MINTSWAP_NFT_MARKETPLACE, abi.encodeWithSelector(
            MINTSWAP_BIDS_SELECTOR, 
            address(this), 
            uint64(MAX_SUPPLY), 
            uint128(bids / MAX_SUPPLY), 
            MINTSWAP_BIDS_EXPIRATION_TIME, 
            WETH9));

        Address.functionCall(factoryAddress, abi.encodeWithSelector(FACTORY_BURN_SELECTOR));
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

        recipient.sendValue(toClaim);
    }

    function tokenURI(uint256 tokenId) public view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "Token not exist");

        string memory imageURI;
        if (imageType == IMAGE_TYPE_SINGLE) {
            imageURI = baseURI;
        }
        if (imageType == IMAGE_TYPE_MULIT) {
            imageURI = string.concat(baseURI, Strings.toString(tokenId), ".png");
        }

        return 
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            ' #' ,
                            Strings.toString(tokenId),
                            '","image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            );
    }

    function _verfySigner(
        address recipient,
        uint256 totalRewards,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (address _signer) {
        _signer = ECDSA.recover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    MINT_RICH_DOMAIN_SEPARATOR,
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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC721A__IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

}