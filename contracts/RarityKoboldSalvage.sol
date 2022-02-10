//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RarityKoboldSalvage is AccessControl, ERC20 {
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Rarity Kobold Salvage", "RKS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, MINTER_ADMIN_ROLE);
    }

    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "!minter");
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "!burner");
        _burn(_account, _amount);
    }
}
