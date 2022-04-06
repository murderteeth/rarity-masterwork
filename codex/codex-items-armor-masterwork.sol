// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexCommonArmor.sol";

struct Armor {
  uint8 id;
  uint8 proficiency;
  uint8 weight;
  uint8 armor_bonus;
  uint8 max_dex_bonus;
  int8 penalty;
  uint8 spell_failure;
  uint cost;
  string name;
  string description;
}

contract codex {
  string public constant index = "Items";
  string public constant class = "Masterwork Armor";

  IRarityCodexCommonArmor constant common_codex =
    IRarityCodexCommonArmor(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);

  function get_proficiency_by_id(uint256 _id)
    public
    pure
    returns (string memory description)
  {
    return common_codex.get_proficiency_by_id(_id);
  }

  function item_by_id(uint _id) public pure returns(Armor memory armor) {
    (
      uint id, 
      uint cost, 
      uint proficiency, 
      uint weight, 
      uint armor_bonus, 
      uint max_dex_bonus, 
      int penalty, 
      uint spell_failure, 
      string memory name, 
      string memory description
    ) = common_codex.item_by_id(_id);
    armor.id = uint8(id);
    armor.proficiency = uint8(proficiency);
    armor.weight = uint8(weight);
    armor.armor_bonus = uint8(armor_bonus);
    armor.max_dex_bonus = uint8(max_dex_bonus);
    armor.penalty = int8(penalty);
    armor.spell_failure = uint8(spell_failure);
    armor.cost = cost + 150e18;
    armor.name = string(abi.encodePacked("Masterwork ", name));
    armor.description = description;
  }
}
