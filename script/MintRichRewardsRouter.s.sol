// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/router/MintRichRewardsRouter.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract MintRichRewardsRouterScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address routerProxy = Upgrades.deployUUPSProxy(
            "MintRichRewardsRouter.sol",
            abi.encodeCall(MintRichRewardsRouter.initialize, ())
        );
        console.log("routerProxy -> %s", routerProxy);

        vm.stopBroadcast();
    }

}