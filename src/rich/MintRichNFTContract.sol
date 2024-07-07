// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721AQueryableUpgradeable.sol";
import "../libs/MintRichPriceLib.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract MintRichNFTContract is ERC721AQueryableUpgradeable, ReentrancyGuardUpgradeable {

    address immutable factoryAddress;

    enum SalePhase { PUBLIC, CLOSED }
    SalePhase public salePhase;

    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    DoubleEndedQueue.Bytes32Deque internal richBank;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public activeSupply;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 30;

    event SaleClosed(address indexed collection);
    event BuyItems(address indexed buyer, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);
    event SellItems(address indexed seller, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _factoryAddress) {
        _disableInitializers();
        factoryAddress = _factoryAddress;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bytes calldata information
    ) public initializerERC721A initializer {
        require(msg.sender == factoryAddress, "Can only be initialized by factory");
        __ERC721A_init(name_, symbol_);
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();
        information;
        salePhase = SalePhase.PUBLIC;
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

        if (!richBank.empty()) {
            uint256 withdrawAmount = Math.min(amount, richBank.length());
            for (uint256 i = 0; i < withdrawAmount;) {
                transferFrom(address(this), buyer, uint256(richBank.popBack()));
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
            richBank.pushFront(bytes32(tokenIds[i]));
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

}