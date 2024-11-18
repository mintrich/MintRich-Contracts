// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

abstract contract MintRichCommonStorage {

    event SaleClosed(address indexed collection);

    event BuyItems(address indexed buyer, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);
    event SellItems(address indexed seller, uint256 amount, uint256 prices, uint256 fees, uint256 preSupply, uint256 postSupply);

    event ClaimRewards(address indexed recipient, uint256 claimedAmount);

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_SUPPLY_404 = 8000;
    
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PROTOCOL_FEE = 100;
    uint256 public constant MINT_RICH_SHARE_POINTS = 1000;
    uint256 public constant MINT_RICH_BIDS_POINTS = 9000;

    address internal constant REWARDS_SIGNER = 0xD23430aA3546c245c03eC1d3a2ab5D80CD98607E;

    address internal constant MINT_RICH_ADMIN = 0x4f8E0c6b39E65AD158560676bA387AfFA7AA0e17;
    address payable internal constant MINT_RICH_RECIPIENT = payable(0x9Fb87f550EFc3821438617c1517867Da43c6FFD2);

    address internal constant WETH9 = 0x4200000000000000000000000000000000000006;
    address internal constant MINTSWAP_NFT_MARKETPLACE = 0x92ff395FB29Da15a5b249327E669b460a2Ec5933;

    address internal constant MINTSWAP_DEX_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    address internal constant MINTSWAP_DEX_FACTORY = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;

    bytes4 internal constant WETH9_DEPOSIT_SELECTOR = bytes4(keccak256("deposit()"));
    bytes4 internal constant MINTSWAP_BIDS_SELECTOR = bytes4(keccak256("createOrUpdateCollectionBid(address,uint64,uint128,uint64,address)"));
    bytes4 internal constant FACTORY_BURN_SELECTOR = bytes4(keccak256("burnToken()"));

    bytes4 internal constant MINTSWAP_DEX_GETPOOL_SELECTOR = 0x1698ee82;
    bytes4 internal constant MINTSWAP_DEX_CREATEPOOL_SELECTOR = 0x13ead562;
    bytes4 internal constant MINTSWAP_DEX_MINT_SELECTOR = 0x88316456;
    bytes4 internal constant MINTSWAP_DEX_REFUNDETH_SELECTOR = 0x12210e8a;

    uint64 internal constant MINTSWAP_BIDS_EXPIRATION_TIME = 2035756800;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    uint8 internal constant IMAGE_TYPE_SINGLE = 0;
    uint8 internal constant IMAGE_TYPE_MULIT = 1;

    uint8 public imageType;
    string public baseURI;

    enum SalePhase { 
        PUBLIC, 
        CLOSED 
    }
    
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
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

    address internal constant ROUTER_ADDRESS = 0x238692D2D98596e7992019365e7fb025581983b1;

    uint256 public constant MAX_SUPPLY_20 = 8e8;

    uint256 internal bank20;

    address internal constant LIQUIDITY_ADDRESS = 0x0000000000000000000000000000000000000001;

}