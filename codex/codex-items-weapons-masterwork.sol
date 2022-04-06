// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexCommonWeapons.sol";

contract codex {
  string public constant index = "Items";
  string public constant class = "Masterwork Weapons";

  IRarityCodexCommonWeapons constant common_codex =
    IRarityCodexCommonWeapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

  function get_proficiency_by_id(uint256 _id)
    public
    pure
    returns (string memory description)
  {
    return common_codex.get_proficiency_by_id(_id);
  }

  function get_encumbrance_by_id(uint256 _id)
    public
    pure
    returns (string memory description)
  {
    return common_codex.get_encumbrance_by_id(_id);
  }

  function get_damage_type_by_id(uint256 _id)
    public
    pure
    returns (string memory description)
  {
    return common_codex.get_damage_type_by_id(_id);
  }

  function item_by_id(uint256 _id)
    public
    pure
    returns (Weapon memory weapon)
  {
    weapon = common_codex.item_by_id(_id);
    weapon.cost = weapon.cost + 300e18;
    weapon.name = string(abi.encodePacked("Masterwork ", weapon.name));
  }
}
