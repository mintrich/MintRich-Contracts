// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/rich/MintRichNFTContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract MintRich404NFTContractScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // address owner = vm.envAddress("OWNER");

        // address beacon = Upgrades.deployBeacon("MintRich404NFTContract.sol", owner);
        // address implAddressV1 = IBeacon(beacon).implementation();
        // console.log("beacon -> %s", beacon);
        // console.log("implAddressV1 -> %s", implAddressV1);

        // bytes memory data = abi.encodeCall(MintRichNFTContract.initialize, 
        //     ("MintRich404BeaconProxy", "MRBP404", bytes32(0), abi.encode("")));
        // address beaconProxy = Upgrades.deployBeaconProxy(beacon, data);
        // console.log("beaconProxy -> %s", beaconProxy);

        // Upgrades.upgradeBeacon(0x150dc2fC150edB54ACcA931B464345722E1EF78B, "MintRich404NFTContract.sol");
        // Upgrades.upgradeBeacon(0x9d52aB21c1E9ec510B65fd274176Db5eD631Da80, "MintRich404NFTContract.sol");
        
        // eth sepolia
        Upgrades.upgradeBeacon(0x1371CbA1CA0a24d10b7c9C8D5Af561c9C9Ee4566, "MintRich404NFTContract.sol");

        vm.stopBroadcast();
    }

}