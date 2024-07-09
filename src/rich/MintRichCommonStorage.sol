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

    address internal constant REWARDS_SIGNER = address(0);
    address internal constant MINT_RICH_RECIPIENT = address(0);

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