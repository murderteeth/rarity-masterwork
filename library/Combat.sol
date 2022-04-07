//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Roll.sol";

library Combat {
  struct Combatant {
    bool summoner;
    uint8 initiative_roll;
    int8 initiative_score;
    int8 critical_modifier;
    uint8 critical_multiplier;
    uint8 armor_class;
    int16 hit_points;
    uint token;
    int8[4] total_attack_bonus;
    int8[16] damage;
  }

  function pack_damage(
    uint8 damage_dice_count,
    uint8 damage_dice_sides,
    int8 damage_modifier,
    uint8 damage_type,
    uint attack_number,
    int8[16] memory damage
  ) internal pure {
    damage[attack_number * 4 + 0] = int8(damage_dice_count);
    damage[attack_number * 4 + 1] = int8(damage_dice_sides);
    damage[attack_number * 4 + 2] = damage_modifier;
    damage[attack_number * 4 + 3] = int8(damage_type);
  }

  function unpack_damage(
    int8[16] memory damage, 
    uint attack_number
  ) internal pure returns (
    uint8 damage_dice_count,
    uint8 damage_dice_sides,
    int8 damage_modifier,
    uint8 damage_type
  ) {
    damage_dice_count = uint8(damage[attack_number * 4 + 0]);
    damage_dice_sides = uint8(damage[attack_number * 4 + 1]);
    damage_modifier = damage[attack_number * 4 + 2];
    damage_type = uint8(damage[attack_number * 4 + 3]);
  }

  function sort_by_initiative(Combatant[] memory combatants) internal pure {
    uint length = combatants.length;
    for(uint i = 0; i < length; i++) {
      for(uint j = i + 1; j < length; j++) {
        Combatant memory i_combatant = combatants[i];
        Combatant memory j_combatant = combatants[j];
        if(i_combatant.initiative_score < j_combatant.initiative_score) {
          combatants[i] = j_combatant;
          combatants[j] = i_combatant;
        } else if(i_combatant.initiative_score == j_combatant.initiative_score) {
          if(i_combatant.initiative_roll > j_combatant.initiative_roll) {
            combatants[i] = j_combatant;
            combatants[j] = i_combatant;
          }
        }
      }
    }
  }

  function attack_combatant(
    Combatant memory attacker, 
    Combatant storage defender,
    uint attack_number
  ) internal returns (
    bool hit, 
    uint8 roll, 
    uint8 score, 
    uint8 critical_confirmation, 
    uint8 damage, 
    uint8 damage_type
  ) {
    AttackRoll memory attack_roll = Roll.attack(
      attacker.token, 
      attacker.total_attack_bonus[attack_number], 
      attacker.critical_modifier, 
      attacker.critical_multiplier, 
      defender.armor_class
    );

    if(attack_roll.damage_multiplier == 0) {
      return (false, attack_roll.roll, attack_roll.score, attack_roll.critical_confirmation, 0, 0);
    } else {
      (
        uint8 damage_dice_count, 
        uint8 damage_dice_sides, 
        int8 damage_modifier, 
        uint8 _damage_type
      ) = unpack_damage(attacker.damage, attack_number);
      damage = Roll.damage(
        attacker.token, 
        damage_dice_count, 
        damage_dice_sides,
        damage_modifier,
        attack_roll.damage_multiplier
      );
      defender.hit_points -= int16(uint16(damage));
      return (true, attack_roll.roll, attack_roll.score, attack_roll.critical_confirmation, damage, _damage_type);
    }
  }
}