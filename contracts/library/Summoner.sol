//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Attributes.sol";
import "./Codex.sol";
import "./Combat.sol";
import "./Crafting.sol";
import "./Effects.sol";
import "./Proficiency.sol";
import "./Rarity.sol";

library Summoner {
  function armor_class(
    uint summoner,
    Combat.EquipmentSlot memory armor_slot,
    Combat.EquipmentSlot memory shield_slot
  ) public view returns (uint8) {
    int8 result = 10;
    int8 dex_modifier = Attributes.dexterity_modifier(summoner);

    uint max_dex_bonus = (2**128 - 1);

    if(armor_slot.item_contract != address(0)) {
      (, uint item_type, , ) = ICrafting(armor_slot.item_contract).items(armor_slot.item);
      IArmor.Armor memory armor_codex = IArmor(armor_slot.item_contract).get_armor(uint8(item_type));
      result += int8(uint8(armor_codex.armor_bonus));
      if(armor_codex.max_dex_bonus < max_dex_bonus) max_dex_bonus = armor_codex.max_dex_bonus;
    }

    if(shield_slot.item_contract != address(0)) {
      (, uint item_type, , ) = ICrafting(shield_slot.item_contract).items(shield_slot.item);
      IArmor.Armor memory shield_codex = IArmor(shield_slot.item_contract).get_armor(uint8(item_type));
      result += int8(uint8(shield_codex.armor_bonus));
      if(shield_codex.max_dex_bonus < max_dex_bonus) max_dex_bonus = shield_codex.max_dex_bonus;
    }

    if(armor_slot.item_contract == address(0) 
      && shield_slot.item_contract == address(0)
      && Rarity.class(summoner) == 6
    ) {
      result += int8(Attributes.wisdom_modifier(summoner))
      + int8(int(Rarity.level(summoner) / 5));
    }

    result = result + ((dex_modifier > int256(max_dex_bonus)) ? int8(uint8(max_dex_bonus)) : dex_modifier);

    return uint8(result);
  }

  // https://github.com/NomicFoundation/hardhat/issues/2592
  function _armor_class_test_wrapper(
    uint summoner,
    uint armor,
    address armor_contract,
    uint shield,
    address shield_contract
  ) public view returns (uint8) {
    return armor_class(
      summoner, 
      Combat.EquipmentSlot(armor_contract, armor), 
      Combat.EquipmentSlot(shield_contract, shield)
    );
  }

  function armor_check_penalty(
    uint summoner,
    uint armor,
    address armor_contract
  ) public view returns (int8) {
    if(armor_contract == address(0)) return 0;
    (, uint item_type, , ) = ICrafting(armor_contract).items(armor);
    IArmor.Armor memory armor_codex = IArmor(armor_contract).get_armor(uint8(item_type));
    return Proficiency.is_proficient_with_armor(summoner, armor_codex.proficiency, item_type)
    ? int8(0)
    : int8(armor_codex.penalty);
  }

  function hit_points(uint summoner) public view returns (uint8) {
    int8 con_modifier = Attributes.constitution_modifier(summoner);
    int hp = int(health_by_class(Rarity.class(summoner))) + con_modifier;
    if (hp <= 0) hp = 1;
    return uint8(uint(hp) * Rarity.level(summoner));
  }

  function health_by_class(uint class) internal pure returns (uint health) {
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

  function attacks(
    uint summoner, 
    Combat.EquipmentSlot memory weapon_slot,
    Combat.EquipmentSlot memory armor_slot,
    Combat.EquipmentSlot memory shield_slot
  ) public view returns(
    int8[28] memory result
  ) {
    IWeapon.Weapon memory weapon_codex = get_weapon(weapon_slot);

    if(weapon_codex.id == 0 && Rarity.class(summoner) == 6) {
      uint level = Rarity.level(summoner);
      weapon_codex.damage = level < 4 ? 6 
      : level < 8 ? 8 
      : level < 12 ? 10 
      : level < 16 ? 12
      : level < 20 ? 16
      : 20;
    }

    int8 attack_modifier = weapon_attack_modifier(summoner, weapon_codex.encumbrance)
    + armor_check_penalty(summoner, armor_slot.item, armor_slot.item_contract)
    + armor_check_penalty(summoner, shield_slot.item, shield_slot.item_contract);

    if(weapon_codex.id != 0
      && !Proficiency.is_proficient_with_weapon(summoner, weapon_codex.proficiency, weapon_codex.id)
    ) {
      attack_modifier -= 4;
    }

    int8 damage_modifier = weapon_damage_modifier(summoner, weapon_codex.encumbrance);

    if(weapon_slot.item_contract != address(0)) {
      attack_modifier += IEffects(weapon_slot.item_contract).attack_bonus(weapon_slot.item);
    }

    int8[4] memory attack_bonus = base_attack_bonus(summoner);
    for(uint i = 0; i < 4; i++) {
      if(i == 0 || attack_bonus[i] > 0) {
        Combat.pack_attack(
          attack_bonus[i] + attack_modifier, 
          int8(weapon_codex.critical_modifier), 
          uint8(weapon_codex.critical),
          1, 
          uint8(weapon_codex.damage), 
          damage_modifier, 
          uint8(weapon_codex.damage_type), 
          i, 
          result
        );
      } else {
        break;
      }
    }
  }

  function _attacks_test_hack(
    uint summoner, 
    uint weapon, address weapon_contract,
    uint armor, address armor_contract,
    uint shield, address shield_contract
  ) public view returns(
    int8[28] memory result
  ) {
    return attacks(
      summoner, 
      Combat.EquipmentSlot(weapon_contract, weapon),
      Combat.EquipmentSlot(armor_contract, armor),
      Combat.EquipmentSlot(shield_contract, shield)
    );
  }

  function get_weapon(Combat.EquipmentSlot memory weapon_slot) internal view returns (IWeapon.Weapon memory) {
    if(weapon_slot.item_contract == address(0)) {
      return unarmed_strike_codex();
    } else {
      (, uint item_type, , ) = ICrafting(weapon_slot.item_contract).items(weapon_slot.item);
      return IWeapon(weapon_slot.item_contract).get_weapon(uint8(item_type));
    }
  }

  function unarmed_strike_codex() internal pure returns(IWeapon.Weapon memory) {
    return IWeapon.Weapon(0, 1, 0, 1, 0, 3, 2, 0, 0, 0, "", "");
  }

  function weapon_attack_modifier(uint summoner, uint weapon_encumbrance) public view returns (int8) {
    return weapon_encumbrance < 5
    ? Attributes.strength_modifier(summoner)
    : weapon_encumbrance == 5
      ? Attributes.dexterity_modifier(summoner)
      : int8(0);
  }

  function weapon_damage_modifier(uint summoner, uint weapon_encumbrance) public view returns (int8) {
    return weapon_encumbrance < 4
    ? Attributes.strength_modifier(summoner)
    : weapon_encumbrance == 4
      ? 3 * Attributes.strength_modifier(summoner) / 2
      : weapon_encumbrance == 5
        ? Attributes.dexterity_modifier(summoner)
        : int8(0);
  }

  function base_attack_bonus(uint summoner) public view returns (int8[4] memory result) {
    result = [int8(0), 0, 0, 0];
    result[0] = int8(uint8(Rarity.level(summoner)) * base_attack_bonus_for_class(Rarity.class(summoner)) / 4);
    for(uint i = 1; i < 4; i++) {
      if(result[i - 1] > 5) result[i] = result[i - 1] - 5;
      else break;
    }
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