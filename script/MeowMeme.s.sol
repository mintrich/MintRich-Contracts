// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/token/MeowMeme.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract MintRich404NFTContractScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address beaconProxy = Upgrades.deployUUPSProxy("MeowMeme.sol", abi.encodeCall(MeowMeme.initialize, ()));
        console.log("UUPS -> %s", beaconProxy);

        vm.stopBroadcast();
    }

}