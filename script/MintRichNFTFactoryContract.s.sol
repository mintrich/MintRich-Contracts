// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/MintRichNFTFactoryContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract MintRichNFTFactoryContractScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address factoryProxy = Upgrades.deployUUPSProxy(
            "MintRichNFTFactoryContract.sol",
            abi.encodeCall(MintRichNFTFactoryContract.initialize, 
            (0xB8C1f3268520c9ADe36Ed136B921246723eAe9b6, 0x14D1ef8785373c933f315f3FbB2f497a64cf2d2c))
        );
        console.log("factoryProxy -> %s", factoryProxy);

        vm.stopBroadcast();
    }

}