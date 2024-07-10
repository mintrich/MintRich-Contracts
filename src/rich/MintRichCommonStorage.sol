// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

abstract contract MintRichCommonStorage {

    enum SalePhase { 
        PUBLIC, 
        CLOSED 
    }

    address public immutable FACTORY;

    uint256 public constant MAX_SUPPLY = 10000;
    
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 30;
    uint256 public constant MINT_RICH_SHARE_POINTS = 1000;
    uint256 public constant MINT_RICH_BIDS_POINTS = 9000;

    address internal constant REWARDS_SIGNER = address(0);
    
    address internal constant MINT_RICH_ADMIN = address(0);
    address payable internal constant MINT_RICH_RECIPIENT = payable(address(0));

    address internal constant WETH9 = 0x4200000000000000000000000000000000000006;
    address internal constant MINTSWAP_NFT_MARKETPLACE = 0x314b4576fDEd7Ce5a0B5e0a394f5252de4d98D27;

    bytes4 internal constant WETH9_DEPOSIT_SELECTOR = bytes4(keccak256("deposit()"));
    bytes4 internal constant MINTSWAP_BIDS_SELECTOR = bytes4(keccak256("createOrUpdateCollectionBid(address,uint64,uint128,uint64,address)"));
    bytes4 internal constant FACTORY_BURN_SELECTOR = bytes4(keccak256("burnToken()"));

    uint64 internal constant MINTSWAP_BIDS_EXPIRATION_TIME = 2035756800;

    SalePhase internal salePhase;
    uint256 public activeSupply;

    uint256 public totalFees;
    uint256 public claimedFees;

    bytes32 internal DOMAIN_SEPARATOR;
    mapping(address => uint256) public rewardsClaimed;
    
    DoubleEndedQueue.Bytes32Deque internal bank;

    constructor(address _factoryAddress) {
        FACTORY = _factoryAddress;
    }

}