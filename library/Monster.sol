//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Combat.sol";
import "./Random.sol";

library Monster {
  struct MonsterCodex {
    uint8 id;
    uint8 hit_dice_count;
    uint8 hit_dice_sides;
    int8 hit_dice_modifier;
    int8 initiative_bonus;
    uint8 armor_class;
    int8 critical_modifier;
    uint8 critical_multiplier;
    uint16 challenge_rating;
    int8[4] total_attack_bonus;
    uint8[6] abilities;
    int8[16] damage;
    string name;
  }

  function hit_points(MonsterCodex memory monster, uint token) internal view returns (int16) {
    int16 roll = int16(uint16(Random.dn(
      9409069218745053777, 
      token, 
      monster.hit_dice_count, 
      monster.hit_dice_sides
    )));
    return roll + monster.hit_dice_modifier;
  }

  function monster_by_id(uint8 id) internal pure returns (MonsterCodex memory monster) {
    if (id == 1) {
      return kobold();
    } else if (id == 2) {
      return dire_rat();
    } else if (id == 3) {
      return goblin();
    } else if (id == 4) {
      return gnoll();
    } else if (id == 5) {
      return grimlock();
    } else if (id == 6) {
      return black_bear();
    } else if (id == 7) {
      return ogre();
    } else if (id == 8) {
      return dire_boar();
    } else if (id == 9) {
      return dire_wolverine();
    } else if (id == 10) {
      return troll();
    } else if (id == 11) {
      return ettin();
    } else if (id == 12) {
      return hill_giant();
    } else if (id == 13) {
      return stone_giant();
    }
  }

  function kobold() internal pure returns (MonsterCodex memory monster) {
    monster.id = 1;
    monster.challenge_rating = 25; // CR 1/4
    monster.hit_dice_count = 1;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 0;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 3;
    monster.total_attack_bonus = [int8(1), 0, 0, 0];
    monster.abilities = [9, 13, 10, 10, 9, 8];
    Combat.pack_damage(1, 2, -1, 2, 0, monster.damage);
    monster.name = "Kobold";
  }

  function dire_rat() internal pure returns (MonsterCodex memory monster) {
    monster.id = 2;
    monster.challenge_rating = 33; // CR 1/3
    monster.hit_dice_count = 1;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 1;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(4), 0, 0, 0];
    monster.abilities = [10, 17, 12, 1, 12, 4];
    Combat.pack_damage(1, 4, 0, 3, 0, monster.damage);
    monster.name = "Dire Rat";
  }

  function goblin() internal pure returns (MonsterCodex memory monster) {
    monster.id = 3;
    monster.challenge_rating = 33; // CR 1/3
    monster.hit_dice_count = 1;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 1;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(2), 0, 0, 0];
    monster.abilities = [11, 13, 12, 10, 9, 6];
    Combat.pack_damage(1, 6, 0, 1, 0, monster.damage);
    monster.name = "Goblin";
  }

  function gnoll() internal pure returns (MonsterCodex memory monster) {
    monster.id = 4;
    monster.challenge_rating = 100; // CR 1
    monster.hit_dice_count = 2;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 2;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 3;
    monster.total_attack_bonus = [int8(3), 0, 0, 0];
    monster.abilities = [15, 10, 13, 8, 11, 8];
    Combat.pack_damage(1, 8, 2, 3, 0, monster.damage);
    monster.name = "Gnoll";
  }

  function grimlock() internal pure returns (MonsterCodex memory monster) {
    monster.id = 5;
    monster.challenge_rating = 100; // CR 1
    monster.hit_dice_count = 2;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 2;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 3;
    monster.total_attack_bonus = [int8(4), 0, 0, 0];
    monster.abilities = [15, 13, 13, 10, 8, 6];
    Combat.pack_damage(1, 8, 3, 3, 0, monster.damage);
    monster.name = "Gnoll";
  }

  function black_bear() internal pure returns (MonsterCodex memory monster) {
    monster.id = 6;
    monster.challenge_rating = 200; // CR 2
    monster.hit_dice_count = 3;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 6;
    monster.initiative_bonus = 0;
    monster.armor_class = 13;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(6), 6, 1, 0];
    monster.abilities = [19, 13, 15, 2, 12, 6];
    Combat.pack_damage(1, 4, 4, 3, 0, monster.damage);
    Combat.pack_damage(1, 4, 4, 3, 1, monster.damage);
    Combat.pack_damage(1, 6, 2, 3, 2, monster.damage);
    monster.name = "Black Bear";
  }

  function ogre() internal pure returns (MonsterCodex memory monster) {
    monster.id = 7;
    monster.challenge_rating = 300; // CR 3
    monster.hit_dice_count = 4;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 11;
    monster.initiative_bonus = 0;
    monster.armor_class = 16;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(8), 0, 0, 0];
    monster.abilities = [21, 8, 15, 6, 10, 7];
    Combat.pack_damage(2, 8, 7, 1, 0, monster.damage);
    monster.name = "Ogre";
  }

  function dire_boar() internal pure returns (MonsterCodex memory monster) {
    monster.id = 8;
    monster.challenge_rating = 400; // CR 4
    monster.hit_dice_count = 7;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 21;
    monster.initiative_bonus = 0;
    monster.armor_class = 15;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 3;
    monster.total_attack_bonus = [int8(12), 0, 0, 0];
    monster.abilities = [27, 10, 17, 2, 13, 8];
    Combat.pack_damage(1, 8, 12, 2, 0, monster.damage);
    monster.name = "Dire Boar";
  }

  function dire_wolverine() internal pure returns (MonsterCodex memory monster) {
    monster.id = 9;
    monster.challenge_rating = 400; // CR 4
    monster.hit_dice_count = 5;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 23;
    monster.initiative_bonus = 0;
    monster.armor_class = 16;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(8), 8, 3, 0];
    monster.abilities = [22, 17, 19, 2, 12, 10];
    Combat.pack_damage(1, 6, 6, 3, 0, monster.damage);
    Combat.pack_damage(1, 6, 6, 3, 1, monster.damage);
    Combat.pack_damage(1, 8, 3, 3, 0, monster.damage);
    monster.name = "Dire Wolverine";
  }

  function troll() internal pure returns (MonsterCodex memory monster) {
    monster.id = 10;
    monster.challenge_rating = 500; // CR 5
    monster.hit_dice_count = 6;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 36;
    monster.initiative_bonus = 0;
    monster.armor_class = 16;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(9), 9, 4, 0];
    monster.abilities = [27, 10, 17, 2, 13, 8];
    Combat.pack_damage(1, 6, 6, 3, 0, monster.damage);
    Combat.pack_damage(1, 6, 6, 3, 1, monster.damage);
    Combat.pack_damage(1, 6, 3, 3, 2, monster.damage);
    monster.name = "Troll";
  }

  function ettin() internal pure returns (MonsterCodex memory monster) {
    monster.id = 11;
    monster.challenge_rating = 600; // CR 6
    monster.hit_dice_count = 10;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 20;
    monster.initiative_bonus = 4; // improved initiative feat
    monster.armor_class = 18;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(12), 7, 0, 0];
    monster.abilities = [27, 10, 17, 2, 13, 8];
    Combat.pack_damage(2, 6, 6, 1, 0, monster.damage);
    Combat.pack_damage(2, 6, 6, 1, 1, monster.damage);
    monster.name = "Ettin";
  }

  function hill_giant() internal pure returns (MonsterCodex memory monster) {
    monster.id = 12;
    monster.challenge_rating = 700; // CR 7
    monster.hit_dice_count = 12;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 48;
    monster.initiative_bonus = 0;
    monster.armor_class = 20;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(16), 11, 0, 0];
    monster.abilities = [25, 8, 19, 6, 10, 7];
    Combat.pack_damage(2, 8, 10, 1, 0, monster.damage);
    Combat.pack_damage(2, 8, 10, 1, 1, monster.damage);
    monster.name = "Hill Giant";
  }

  function stone_giant() internal pure returns (MonsterCodex memory monster) {
    monster.id = 13;
    monster.challenge_rating = 800; // CR 8
    monster.hit_dice_count = 14;
    monster.hit_dice_sides = 8;
    monster.hit_dice_modifier = 56;
    monster.initiative_bonus = 0;
    monster.armor_class = 25;
    monster.critical_modifier = 0;
    monster.critical_multiplier = 2;
    monster.total_attack_bonus = [int8(17), 12, 0, 0];
    monster.abilities = [27, 15, 19, 10, 12, 11];
    Combat.pack_damage(2, 8, 12, 1, 0, monster.damage);
    Combat.pack_damage(2, 8, 12, 1, 1, monster.damage);
    monster.name = "Stone Giant";
  }
}