// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

abstract contract MintRichCommonStorage {

    event SaleClosed(address indexed collection);

    event BuyItems(address indexed buyer, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);
    event SellItems(address indexed seller, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);

    event ClaimRewards(address indexed recipient, uint256 claimedAmount);

    uint256 public constant MAX_SUPPLY = 10000;
    
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 30;
    uint256 public constant MINT_RICH_SHARE_POINTS = 1000;
    uint256 public constant MINT_RICH_BIDS_POINTS = 9000;

    address internal constant REWARDS_SIGNER = 0xC565FC29F6df239Fe3848dB82656F2502286E97d;
    
    address internal constant MINT_RICH_ADMIN = 0x271561bb85251270CaA71cd6AA3332018e5cE1cA;
    address payable internal constant MINT_RICH_RECIPIENT = payable(0xcA1F5EfC5Fb73CE3Ed7a092a2eBa8738Abf18852);

    address internal constant WETH9 = 0x4200000000000000000000000000000000000006;
    address internal constant MINTSWAP_NFT_MARKETPLACE = 0xb71663651BdA299a0891deFFB5c2286943e076B4;

    bytes4 internal constant WETH9_DEPOSIT_SELECTOR = bytes4(keccak256("deposit()"));
    bytes4 internal constant MINTSWAP_BIDS_SELECTOR = bytes4(keccak256("createOrUpdateCollectionBid(address,uint64,uint128,uint64,address)"));
    bytes4 internal constant FACTORY_BURN_SELECTOR = bytes4(keccak256("burnToken()"));

    uint64 internal constant MINTSWAP_BIDS_EXPIRATION_TIME = 2035756800;

    uint8 internal constant IMAGE_TYPE_SINGLE = 0;
    uint8 internal constant IMAGE_TYPE_MULIT = 1;

    uint8 public imageType;
    string public baseURI;

    enum SalePhase { 
        PUBLIC, 
        CLOSED 
    }
    
    SalePhase public salePhase;
    address public factoryAddress;
    uint256 public activeSupply;

    uint256 public totalFees;
    uint256 public claimedFees;

    bytes32 internal MINT_RICH_DOMAIN_SEPARATOR;
    mapping(address => uint256) public rewardsClaimed;
    
    DoubleEndedQueue.Bytes32Deque internal bank;
    uint256 internal bank404;

}