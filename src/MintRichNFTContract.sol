// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721AQueryableUpgradeable.sol";
import "./MintRichPriceLib.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MintRichNFTContract is ERC721AQueryableUpgradeable, Initializable {

    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    enum SalePhase { PUBLIC, CLOSED }

    address immutable factoryAddress;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public activeSupply;

    DoubleEndedQueue.Bytes32Deque internal richBank;

    string private _baseUri;

    bool private locked;

    SalePhase public salePhase;

    event BuyItems(address indexed buyer, uint256 amount, uint256 prices, uint256 preSupply, uint256 postSupply);
    event SellItems(address indexed seller, uint256 amount, uint256 prices, uint256 preSupply, uint256 postSupply);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _factoryAddress) {
        _disableInitializers();
        factoryAddress = _factoryAddress;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata tokenBaseURI_
    ) public initializerERC721A initializer {
        require(msg.sender == factoryAddress, "Can only be initialized by factory");
        __ERC721A_init(name_, symbol_);
        _baseUri = tokenBaseURI_;
        salePhase = SalePhase.PUBLIC;
    }

    modifier lock() {
        require(!locked, "Locked");
        locked = true;
        _;
        locked = false;
    }

    modifier checkSalePhase() {
        require(salePhase == SalePhase.PUBLIC, "Public sale ended");
        _;

        if (activeSupply == MAX_SUPPLY) {
            salePhase = SalePhase.CLOSED;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function buy(uint256 amount) external payable checkSalePhase {
        require(amount > 0 && activeSupply + amount <= MAX_SUPPLY, "Buy amount exceeds MAX_SUPPLY limit");

        uint256 prices = buyQuota(amount);
        require(prices <= msg.value, "Not enough ETH to buy NFTs");

        buyNFTs(amount);
        uint256 preSupply = activeSupply;
        activeSupply += amount;

        emit BuyItems(msg.sender, amount, prices, preSupply, activeSupply);
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

    function sell(uint256 amount) external lock checkSalePhase {
        require(amount > 0 && amount <= balanceOf(msg.sender), "Sell amount exceeds owned amount");
        uint256 prices = sellQuota(amount);

        sellNFTs(amount);
        uint256 preSupply = activeSupply;
        activeSupply -= amount;

        (bool success, ) = msg.sender.call{value: prices}(new bytes(0));
        require(success, 'ETH transfer failed');

        emit SellItems(msg.sender, amount, prices, preSupply, activeSupply);
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

    function buyQuota(uint256 amount) public view returns (uint256 prices) {
        prices = MintRichPriceLib.totalTokenPrices(activeSupply, amount);
    }
    
    function sellQuota(uint256 amount) public view returns (uint256 prices) {
        prices = MintRichPriceLib.totalTokenPrices(activeSupply - amount, amount);
    }

}