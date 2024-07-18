// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MintRichNFTFactoryContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TestMintRich is Test {

    address constant OWNER_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    address constant TEST_ADDRESS = 0x21cB920Bf98041CD33A68F7543114a98e420Da0B;
    
    address private beacon;
    address private beaconProxy;
    address private factoryProxy;

    MintRichNFTFactoryContract private factory;

    function setUp() public {
        vm.startPrank(OWNER_ADDRESS);

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

        factoryProxy = Upgrades.deployUUPSProxy(
            "MintRichNFTFactoryContract.sol",
            abi.encodeCall(MintRichNFTFactoryContract.initialize, (beaconProxy))
        );
        console.log("factoryProxy -> %s", factoryProxy);

        factory = MintRichNFTFactoryContract(factoryProxy);
        assertEq(factory.owner(), OWNER_ADDRESS);
        
        vm.stopPrank();
    }

    function testMintRich() public {
        vm.startPrank(TEST_ADDRESS);
        uint256 addr = uint256(uint160(TEST_ADDRESS)) << 96;
        uint256 collectionId = addr + 1;
        assertEq(bytes32(collectionId), bytes32(0x21cB920Bf98041CD33A68F7543114a98e420Da0B000000000000000000000001));
        factory.createRichCollection(bytes32(collectionId), "Meme NFT", "MMN", bytes32(0), abi.encode("ipfs://xxx/"));
        
        address collection = factory.predictDeterministicAddress(bytes32(collectionId));
        MintRichNFTContract mmn = MintRichNFTContract(collection);
        assertEq(mmn.name(), "Meme NFT");
        assertEq(mmn.symbol(), "MMN");
        assertEq(mmn.factoryAddress(), factoryProxy);
        assertEq(mmn.imageType(), 0);
        assertEq(mmn.baseURI(), "ipfs://xxx/");
        vm.stopPrank();
    }

}