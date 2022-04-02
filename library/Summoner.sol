//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexCommonArmor.sol";
import "../interfaces/core/IRarityCommonCrafting.sol";
import "./Attributes.sol";
import "./Proficiency.sol";
import "./Rarity.sol";

library Summoner {
  IRarityCodexCommonArmor internal constant ARMOR_CODEX 
  = IRarityCodexCommonArmor(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);

  function armor_class(
    uint summoner,
    uint armor,
    address armor_contract
  ) public view returns (uint8) {
    int8 result = 10;
    int8 dexModifier = Attributes.dexterity_modifier(summoner) 
    + armor_proficiency_bonus(summoner, armor, armor_contract);

    if(armor_contract != address(0)) {
      (, uint item_type, , ) = IRarityCommonCrafting(armor_contract).items(armor);
      (, , , , uint armorBonus, uint maxDexBonus, , , , ) = ARMOR_CODEX.item_by_id(item_type);
      result += int8(uint8(armorBonus));
      result = result + ((dexModifier > int256(maxDexBonus)) ? int8(uint8(maxDexBonus)) : dexModifier);
    } else {
      result = result + dexModifier;
    }

    return uint8(result);
  }

  function armor_proficiency_bonus(
    uint summoner,
    uint armor,
    address armor_contract
  ) public view returns (int8) {
    if(armor_contract == address(0)) return 0;
    (,uint item_type, , ) = IRarityCommonCrafting(armor_contract).items(armor);
    (, ,uint proficiency, , , , int256 penalty, , , ) = ARMOR_CODEX.item_by_id(item_type);

    return Proficiency.isProficientWithArmor(summoner, proficiency, item_type)
    ? int8(0)
    : int8(penalty);
  }

  function hit_points(uint summoner) public view returns (uint8) {
    int8 con_modifier = Attributes.constitution_modifier(summoner);
    int hp = int(health_byclass(Rarity.class(summoner))) + con_modifier;
    if (hp <= 0) hp = 1;
    return uint8(uint(hp) * Rarity.level(summoner));
  }

  function health_byclass(uint class) internal pure returns (uint health) {
    if (class == 1) {
      health = 12;
    } else if (class == 2) {
      health = 6;
    } else if (class == 3) {
      health = 8;
    } else if (class == 4) {
      health = 8;
    } else if (class == 5) {
      health = 10;
    } else if (class == 6) {
      health = 8;
    } else if (class == 7) {
      health = 10;
    } else if (class == 8) {
      health = 8;
    } else if (class == 9) {
      health = 6;
    } else if (class == 10) {
      health = 4;
    } else if (class == 11) {
      health = 4;
    }
  }

  function base_weapon_modifier(uint summoner, uint weapon_encumbrance) public view returns (int8) {
    return weapon_encumbrance < 5
    ? Attributes.strength_modifier(summoner)
    : Attributes.dexterity_modifier(summoner);
  }

  function total_attack_bonus(uint summoner, int8 _base_weapon_modifier) public view returns (int8) {
    return int8(base_attack_bonus(summoner)) + _base_weapon_modifier;
  }

  function base_attack_bonus(uint summoner) public view returns (uint8) {
    return uint8((Rarity.level(summoner) * base_attack_bonus_for_class(Rarity.class(summoner))) / 4);
  }

  function base_attack_bonus_for_class(uint _class) public pure returns (uint8) {
    if (_class == 1) {
        return 4;
    } else if (_class == 2) {
        return 3;
    } else if (_class == 3) {
        return 3;
    } else if (_class == 4) {
        return 3;
    } else if (_class == 5) {
        return 4;
    } else if (_class == 6) {
        return 3;
    } else if (_class == 7) {
        return 4;
    } else if (_class == 8) {
        return 4;
    } else if (_class == 9) {
        return 3;
    } else if (_class == 10) {
        return 2;
    } else if (_class == 11) {
        return 2;
    } else {
      return 0;
    }
  }
}