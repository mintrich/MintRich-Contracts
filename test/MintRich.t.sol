// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MintRichNFTFactoryContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TestMintRich is Test {

    address constant OWNER_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    
    address private beacon;
    address private beaconProxy;

    function setUp() public {
        beacon = Upgrades.deployBeacon("MintRichNFTContract.sol", OWNER_ADDRESS);
        address implAddressV1 = IBeacon(beacon).implementation();
        console.log("beacon -> %s", beacon);
        console.log("implAddressV1 -> %s", implAddressV1);

        bytes memory data = abi.encodeCall(MintRichNFTContract.initialize, 
            ("MintRichBeaconProxy", "MRBP", bytes32(0), abi.encode("")));
        console.logBytes(data);

        beaconProxy = Upgrades.deployBeaconProxy(beacon, data);
        console.log("beaconProxy -> %s", beaconProxy);

        MintRichNFTContract proxy = MintRichNFTContract(beaconProxy);

        assertEq(proxy.name(), "MintRichBeaconProxy");
        assertEq(proxy.symbol(), "MRBP");
        assertEq(proxy.imageType(), 0);
        assertEq(proxy.baseURI(), "");
    }

    function testMintRich() public {

    }

}