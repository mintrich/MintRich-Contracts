// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MintRichNFTContract is ERC721AUpgradeable, Initializable {

    uint256 public constant MAX_SUPPLY = 10000;

    address public factoryAddress;

    string private _baseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _factoryAddress) {
        factoryAddress = _factoryAddress;
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata tokenBaseURI_
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        _baseURI = tokenBaseURI_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}