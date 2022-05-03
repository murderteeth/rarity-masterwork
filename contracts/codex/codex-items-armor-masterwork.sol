// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexCommonArmor.sol";
import "../library/Codex.sol";

contract codex {
  string public constant index = "Items";
  string public constant class = "Masterwork Armor";

  IRarityCodexCommonArmor constant COMMON_CODEX =
    IRarityCodexCommonArmor(0x0000000000000000000000000000000000000010);

  function get_proficiency_by_id(uint256 _id)
    public
    pure
    returns (string memory description)
  {
    return COMMON_CODEX.get_proficiency_by_id(_id);
  }

  function item_by_id(uint _id) public pure returns(IArmor.Armor memory armor) {
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
    ) = COMMON_CODEX.item_by_id(_id);
    armor.id = uint8(id);
    armor.proficiency = uint8(proficiency);
    armor.weight = uint8(weight);
    armor.armor_bonus = uint8(armor_bonus);
    armor.max_dex_bonus = uint8(max_dex_bonus);
    armor.penalty = int8(penalty + 1);
    armor.spell_failure = uint8(spell_failure);
    armor.cost = cost + 150e18;
    armor.name = string(abi.encodePacked("Masterwork ", name));
    armor.description = description;
  }
}
