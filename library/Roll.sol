//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/core/IRarityCommonCrafting.sol";
import "./Attributes.sol";
import "./Feats.sol";
import "./Random.sol";
import "./Skills.sol";

struct AttackRoll {
  uint8 roll;
  uint8 score;
  uint8 critical_roll;
  uint8 critical_confirmation;
  uint8 damage_multiplier;
}

library Roll {
  function initiative(uint summoner) public view returns (uint8 roll, int8 score) {
    return initiative(
      summoner, 
      Attributes.dexterity_modifier(summoner), 
      Feats.improved_initiative(summoner) ? int8(4) : int8(0)
    );
  }

  function initiative(uint token, int8 total_dex_modifier, int8 initiative_bonus) public view returns (uint8 roll, int8 score) {
    roll = Random.dn(token, 11781769727069077443, 20);
    score = total_dex_modifier + int8(initiative_bonus) + int8(roll);
  }

  function search(uint summoner) public view returns (uint8 roll, int8 score) {
    roll = Random.dn(summoner, 12460038586674487978, 20);
    score = int8(roll);
    score += Attributes.intelligence_modifier(summoner);
    score += int8(Skills.search(summoner));
    if(Feats.investigator(summoner)) score += 2;
  }

  function sense_motive(uint summoner) public view returns (uint8 roll, int8 score) {
    roll = Random.dn(summoner, 3505325381439919961, 20);
    score = int8(roll);
    score += Attributes.wisdom_modifier(summoner);
    score += int8(Skills.sense_motive(summoner));
    if(Feats.negotiator(summoner)) score += 2;
  }

  function attack(
    uint token, 
    int8 total_bonus,
    int8 critical_modifier,
    uint8 critical_multiplier,
    uint8 target_armor_class
  ) public view returns (AttackRoll memory result) {
    result.roll = Random.dn(token, 9807527763775093748, 20);
    if(result.roll == 1) return AttackRoll(1, 0, 0, 0, 0);
    result.score = uint8(int8(result.roll) + total_bonus);
    if(result.score >= target_armor_class) result.damage_multiplier++;
    if(result.roll >= uint(int(int8(20) + critical_modifier))) {
      result.critical_roll = Random.dn(token, 9809778455456300450, 20);
      result.critical_confirmation = uint8(int8(result.critical_roll) + total_bonus);
      if(result.critical_confirmation >= target_armor_class) result.damage_multiplier += critical_multiplier;
    }
  }

  function damage(
    uint token,
    uint8 dice_count, 
    uint8 dice_sides,
    int8 total_modifier,
    uint8 damage_multiplier
  ) public view returns (uint8 result) {
    for(uint i; i < damage_multiplier; i++) {
      int8 signed_result = int8(Random.dn(token, 6459055441333536942 + i, dice_count, dice_sides)) + total_modifier;
      if(signed_result < 1) {
        result += 1;
      } else {
        result += uint8(signed_result);
      }
    }
  }
}