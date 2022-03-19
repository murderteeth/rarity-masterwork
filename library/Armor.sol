//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexCommonArmor.sol";
import "../interfaces/core/IRarityCommonCrafting.sol";
import "./Attributes.sol";
import "./Proficiency.sol";

// TODO: Monks should get a wisdom and level bonus
// http://www.d20srd.org/srd/classes/monk.htm
library Armor {
  IRarityCodexCommonArmor internal constant ARMOR_CODEX =
    IRarityCodexCommonArmor(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);

  function class(
    uint256 summoner,
    uint256 armor,
    address armorContract
  ) public view returns (uint8) {
    (, uint256 itemType, , ) = IRarityCommonCrafting(armorContract).items(armor);
    (, , , , uint256 armorBonus, uint256 maxDexBonus, , , , ) = ARMOR_CODEX.item_by_id(itemType);

    int8 dexModifier = Attributes.dexterityModifier(summoner) 
      + proficiencyBonus(summoner, armor, armorContract);

    int8 result = 10 + int8(uint8(armorBonus));
    if (dexModifier > int256(maxDexBonus)) {
      result += int8(uint8(maxDexBonus));
    } else {
      result += dexModifier;
    }
    return uint8(result);
  }

  function proficiencyBonus(
    uint256 summoner,
    uint256 armor,
    address armorContract
  ) public view returns (int8) {
    if (armorContract == address(0)) {
      return 0;
    }

    (, uint256 itemType,,) = IRarityCommonCrafting(armorContract).items(armor);
    (,, uint256 proficiency,,,, int256 penalty,,,) = ARMOR_CODEX.item_by_id(itemType);

    if (!Proficiency.isProficientWithArmor(summoner, proficiency, itemType)) {
      return int8(penalty);
    } else {
      return 0;
    }
  }
}