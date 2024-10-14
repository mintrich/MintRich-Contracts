// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @custom:oz-upgrades-from MintRichRewardsRouter
contract MintRichRewardsRouter is UUPSUpgradeable, OwnableUpgradeable {

    bytes4 internal constant REWARDS_CLAIMED_SELECTOR = 
        bytes4(keccak256("rewardsClaimed(address)"));
    bytes4 internal constant CLAIM_REWARDS_SELECTOR = 
        bytes4(keccak256("claimRewards(address,uint256,uint8,bytes32,bytes32)"));

    struct ClaimInfo {
        uint256 totalRewards;
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        address collection;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer external {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
    }

    function allClaimed(address recipient, address[] calldata collections) external view 
        returns (uint256 allRewards) {
            for (uint256 i = 0; i < collections.length; ++i) {
                bytes memory data = Address.functionStaticCall(collections[i], 
                    abi.encodeWithSelector(REWARDS_CLAIMED_SELECTOR, recipient));
                uint256 rewards = abi.decode(data, (uint256));
                allRewards += rewards;
            }
    }

    function claimAllRewards(ClaimInfo[] calldata claimInfos) external {
        for (uint256 i = 0; i < claimInfos.length; ++i) {
            ClaimInfo calldata claimInfo = claimInfos[i];
            Address.functionCall(claimInfo.collection, abi.encodeWithSelector(
                CLAIM_REWARDS_SELECTOR, msg.sender, claimInfo.totalRewards, 
                claimInfo._v, claimInfo._r, claimInfo._s));
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

}