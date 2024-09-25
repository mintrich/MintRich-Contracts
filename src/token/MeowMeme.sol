// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MeowMeme is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    
    uint256 constant public MAX_SUPPLY = 10 ** 18 * 10000000000;
    uint256 public minted;

    struct Batch {
        address to;
        uint256 amount;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("MeowMeme", "MEOW");
        __Ownable_init(msg.sender);
        __ERC20Permit_init("MeowMeme");
        __UUPSUpgradeable_init();
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == 0xE127486F97217E0Bbfe6c679Dd2908fEfE5f8ce8, "Not Authed");
        require(minted + amount <= MAX_SUPPLY, "Exceed Max Supply");
        _mint(to, amount);
        minted = minted + amount;
    }

    function mintBatch(Batch[] calldata batches) public {
        for (uint256 i = 0; i < batches.length; ++i) {
            mint(batches[i].to, batches[i].amount);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
