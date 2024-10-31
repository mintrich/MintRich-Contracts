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
            (0x84E5E9bF7B6fa562E32B2A4ed2bCa59d9dfB8401, 0x84E5E9bF7B6fa562E32B2A4ed2bCa59d9dfB8401,
             0x84E5E9bF7B6fa562E32B2A4ed2bCa59d9dfB8401))
        );
        console.log("factoryProxy -> %s", factoryProxy);

        vm.stopBroadcast();
    }

}