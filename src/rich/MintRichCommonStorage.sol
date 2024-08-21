// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

abstract contract MintRichCommonStorage {

    uint256 public constant MAX_SUPPLY = 10000;
    
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 30;
    uint256 public constant MINT_RICH_SHARE_POINTS = 1000;
    uint256 public constant MINT_RICH_BIDS_POINTS = 9000;

    address internal constant REWARDS_SIGNER = 0xD23430aA3546c245c03eC1d3a2ab5D80CD98607E;
    
    address internal constant MINT_RICH_ADMIN = 0x4f8E0c6b39E65AD158560676bA387AfFA7AA0e17;
    address payable internal constant MINT_RICH_RECIPIENT = payable(0x5d36B58D20f2cF17bBaaB49f88d20Aa391808633);

    address internal constant WETH9 = 0x4200000000000000000000000000000000000006;
    address internal constant MINTSWAP_NFT_MARKETPLACE = 0x314b4576fDEd7Ce5a0B5e0a394f5252de4d98D27;

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

}