// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../library/Codex.sol";

contract codex {
  string public constant index = "Items";
  string public constant class = "Masterwork Weapons";

  ICodexWeapon constant COMMON_CODEX =
    ICodexWeapon(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

  function get_proficiency_by_id(uint id)
    public
    pure
    returns (string memory description)
  {
    return COMMON_CODEX.get_proficiency_by_id(id);
  }

  function get_encumbrance_by_id(uint id)
    public
    pure
    returns (string memory description)
  {
    return COMMON_CODEX.get_encumbrance_by_id(id);
  }

  function get_damage_type_by_id(uint id)
    public
    pure
    returns (string memory description)
  {
    return COMMON_CODEX.get_damage_type_by_id(id);
  }

  function item_by_id(uint id)
    public
    pure
    returns (IWeapon.Weapon memory weapon)
  {
    weapon = COMMON_CODEX.item_by_id(id);
    weapon.cost = weapon.cost + 300e18;
    weapon.name = string(abi.encodePacked("Masterwork ", weapon.name));
  }
}
