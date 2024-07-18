// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MintRichNFTFactoryContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TestMintRich is Test {

    address constant OWNER_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    address constant TEST_ADDRESS = 0x21cB920Bf98041CD33A68F7543114a98e420Da0B;
    address constant TEST2_ADDRESS = 0xb84C357F5F6BB7f36632623105F10cFAD3DA18A6;
    
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
        assertEq(mmn.owner(), TEST_ADDRESS);

        (uint256 prices3, ) = mmn.buyQuota(7);

        (uint256 prices, uint256 fees) = mmn.buyQuota(10);
        uint256 totalPrices = prices + fees;
        vm.deal(TEST_ADDRESS, totalPrices + 1);
        mmn.buy{value: totalPrices + 1}(10);
        assertEq(TEST_ADDRESS.balance, 1);
        assertEq(mmn.activeSupply(), 10);
        assertEq(mmn.saleBalance(), prices);
        assertEq(mmn.totalFees(), fees);

        (uint256 prices2, uint256 fees2) = mmn.sellQuota(3);
        uint256 receivedPrices = prices2 - fees2;
        vm.deal(TEST_ADDRESS, 0);
        mmn.sell(3);
        assertEq(TEST_ADDRESS.balance, receivedPrices);
        assertEq(mmn.activeSupply(), 7);
        assertEq(mmn.saleBalance(), prices - prices2);
        assertEq(mmn.totalFees(), fees + fees2);

        assertEq(mmn.saleBalance(), prices3);
        uint256[] memory tokenIds = mmn.tokensOfOwner(TEST_ADDRESS);
        assertEq(tokenIds[0], 4);
        vm.stopPrank();

        vm.startPrank(TEST2_ADDRESS);
        (uint256 prices4, uint256 fees4) = mmn.buyQuota(999);
        uint256 totalPrices2 = prices4 + fees4;
        vm.deal(TEST2_ADDRESS, totalPrices2 + 11);
        mmn.buy{value: totalPrices2 + 11}(999);
        assertEq(TEST2_ADDRESS.balance, 11);
        assertEq(mmn.activeSupply(), 1006);
        assertEq(mmn.saleBalance(), prices3 + prices4);
        assertEq(mmn.totalFees(), fees + fees2 + fees4);

        uint256[] memory tokenIds2 = mmn.tokensOfOwner(TEST2_ADDRESS);
        assertEq(tokenIds2[0], 1);

        vm.expectRevert(bytes("Buy amount exceeds MAX_SUPPLY limit"));
        mmn.buy(9000);

        uint256 addr2 = uint256(uint160(TEST2_ADDRESS)) << 96;
        uint256 collectionId2 = addr2 + 10;
        assertEq(bytes32(collectionId2), bytes32(0xb84C357F5F6BB7f36632623105F10cFAD3DA18A600000000000000000000000a));
        factory.createRichCollection(bytes32(collectionId2), "Meme NFT22", "MMN22", bytes32(uint256(1)), abi.encode("ipfs://yyy/"));
        
        address collection2 = factory.predictDeterministicAddress(bytes32(collectionId2));
        MintRichNFTContract mmn2 = MintRichNFTContract(collection2);
        assertEq(mmn2.name(), "Meme NFT22");
        assertEq(mmn2.symbol(), "MMN22");
        assertEq(mmn2.factoryAddress(), factoryProxy);
        assertEq(mmn2.imageType(), 1);
        assertEq(mmn2.baseURI(), "ipfs://yyy/");
        assertEq(mmn2.owner(), TEST2_ADDRESS);
        
        (uint256 prices11, uint256 fees11) = mmn2.buyQuota(mmn2.MAX_SUPPLY());
        uint256 totalPrices11 = prices11 + fees11;
        vm.deal(TEST2_ADDRESS, totalPrices11);
        mmn2.buy{value: totalPrices11}(mmn2.MAX_SUPPLY());
        assertEq(TEST2_ADDRESS.balance, 0);
        assertEq(mmn2.activeSupply(), mmn2.MAX_SUPPLY());
        assertEq(mmn2.saleBalance(), prices11);
        assertEq(mmn2.totalFees(), fees11);

        vm.expectRevert(bytes("Public sale ended"));
        mmn2.buy(1);
        vm.stopPrank();
    }

}