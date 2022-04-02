//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Roll.sol";

struct Combatant {
  uint token;
  Score initiative;
  int16 hit_points;
  int8 base_weapon_modifier;
  int8 total_attack_bonus;
  int8 critical_modifier;
  uint8 critical_multiplier;
  uint8 damage_dice_count;
  uint8 damage_dice_sides;
  uint8 damage_type;
  uint8 armor_class;
  bool summoner;
}

library Combat {
  function sort_by_initiative(Combatant[] memory combatants) internal pure {
    uint length = combatants.length;
    for(uint i = 0; i < length; i++) {
      for(uint j = i + 1; j < length; j++) {
        Combatant memory i_combatant = combatants[i];
        Combatant memory j_combatant = combatants[j];
        if(i_combatant.initiative.score < j_combatant.initiative.score) {
          combatants[i] = j_combatant;
          combatants[j] = i_combatant;
        } else if(i_combatant.initiative.score == j_combatant.initiative.score) {
          if(i_combatant.initiative.roll > j_combatant.initiative.roll) {
            combatants[i] = j_combatant;
            combatants[j] = i_combatant;
          }
        }
      }
    }
  }

  function attack_combatant(
    Combatant memory attacker, 
    Combatant storage defender
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
      attacker.total_attack_bonus, 
      attacker.critical_modifier, 
      attacker.critical_multiplier, 
      defender.armor_class
    );

    if(attack_roll.damage_multiplier == 0) {
      return (false, attack_roll.roll, attack_roll.score, attack_roll.critical_confirmation, 0, 0);
    } else {
      damage = Roll.damage(
        attacker.token, 
        attacker.damage_dice_count, 
        attacker.damage_dice_sides,
        attacker.base_weapon_modifier,
        attack_roll.damage_multiplier
      );
      defender.hit_points -= int16(uint16(damage));
      return (true, attack_roll.roll, attack_roll.score, attack_roll.critical_confirmation, damage, attacker.damage_type);
    }
  }
}