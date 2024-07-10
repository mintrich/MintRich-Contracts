// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import { MintRichNFTContract } from "./rich/MintRichNFTContract.sol";
import { IMetadataRenderer } from "./metadata/IMetadataRenderer.sol";

contract MintRichNFTFactoryContract is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    address public implementationAddress;

    address public metadataRenderer;

    event MintRichCollectionCreated(address indexed owner, address indexed collectionAddress, bytes32 collectionId, string name, string symbol);

    error InvalidCaller();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _implementationAddress) initializer public {
        __ERC721_init("MintRich Owner", "MROwner");
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        implementationAddress = _implementationAddress;
    }

    function createRichCollection(
        bytes32 collectionId,
        string calldata name,
        string calldata symbol,
        bytes32 packedData,
        bytes calldata information
    ) external {
        checkCaller(collectionId);
        address collection = Clones.cloneDeterministic(implementationAddress, collectionId);

        (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            MintRichNFTContract.initialize, (name, symbol, packedData, information)));
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }                
        }

        _mint(msg.sender, uint256(uint160(collection)));
        emit MintRichCollectionCreated(msg.sender, collection, collectionId, name, symbol);
    }

    function predictDeterministicAddress(bytes32 collectionId) external view returns (address) {
        return Clones.predictDeterministicAddress(implementationAddress, collectionId, address(this));
    }

    function checkCaller(bytes32 salt) internal view {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidCaller();
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return IMetadataRenderer(metadataRenderer).tokenURI(tokenId);
    }

    function setMetadataRenderer(address _metadataRenderer) external onlyOwner {    
        metadataRenderer = _metadataRenderer;
    }

    function burnToken() external {
        uint256 tokenID = uint256(uint160(msg.sender));
        _requireOwned(tokenID);
        _burn(tokenID);
    }

}