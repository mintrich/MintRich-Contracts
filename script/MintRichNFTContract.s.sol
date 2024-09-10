// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/rich/MintRichNFTContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract MintRichNFTContractScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.envAddress("OWNER");

        address beacon = Upgrades.deployBeacon("MintRichNFTContract.sol", owner);
        address implAddressV1 = IBeacon(beacon).implementation();
        console.log("beacon -> %s", beacon);
        console.log("implAddressV1 -> %s", implAddressV1);

        bytes memory data = abi.encodeCall(MintRichNFTContract.initialize, 
            ("MintRichBeaconProxy", "MRBP", bytes32(0), abi.encode("")));
        address beaconProxy = Upgrades.deployBeaconProxy(beacon, data);
        console.log("beaconProxy -> %s", beaconProxy);

        // Upgrades.upgradeBeacon(0xBf34b99aA2e64594eDc8BA6a44449c41a8514cA9, "MintRichNFTContract.sol");
        // Upgrades.upgradeBeacon(0x150dc2fC150edB54ACcA931B464345722E1EF78B, "MintRichNFTContract.sol");

        vm.stopBroadcast();
    }

}