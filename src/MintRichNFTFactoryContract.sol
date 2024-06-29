// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MintRichNFTContract.sol";

contract MintRichNFTFactoryContract is Ownable {

    address public implementationAddress;

    event RichCollectionCreated(address indexed owner, bytes32 collectionId, string name, string symbol, string tokenBaseURI);

    error InvalidCaller();

    constructor(
        address _implementationAddress
    ) Ownable(msg.sender) {
        implementationAddress = _implementationAddress;
    }

    function createRichCollection(
        bytes32 collectionId,
        string calldata name_,
        string calldata symbol_,
        string calldata tokenBaseURI_
    ) external {
        checkCaller(collectionId);
        address collection = Clones.cloneDeterministic(implementationAddress, collectionId);

        (bool success, bytes memory returnData) = collection.call(abi.encodeCall(
            MintRichNFTContract.initialize, (name_, symbol_, tokenBaseURI_)));
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }                
        }

        emit RichCollectionCreated(msg.sender, collectionId, name_, symbol_, tokenBaseURI_);
    }

    function predictDeterministicAddress(bytes32 collectionId) external view returns (address) {
        return Clones.predictDeterministicAddress(implementationAddress, collectionId, address(this));
    }

    function checkCaller(bytes32 salt) internal view {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidCaller();
        }
    }

}