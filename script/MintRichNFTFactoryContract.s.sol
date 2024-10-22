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
            (0x8DaaebB56a513BF51b87749A69f8a9FE8c5A34f7, 0x8DaaebB56a513BF51b87749A69f8a9FE8c5A34f7,
             0x8DaaebB56a513BF51b87749A69f8a9FE8c5A34f7))
        );
        console.log("factoryProxy -> %s", factoryProxy);

        vm.stopBroadcast();
    }

}