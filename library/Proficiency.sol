//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexCommonWeapons.sol";
import "./Rarity.sol";
import "./Feats.sol";

library Proficiency {
  IRarityCodexCommonWeapons public constant CODEX_COMMON_WEAPONS 
    = IRarityCodexCommonWeapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

  // TODO: Tower shield feat 96, armor type 18
  function isProficientWithArmor(
    uint256 summoner,
    uint256 proficiencyReq,
    uint256 armorType
  ) public view returns (bool) {
    uint256 class = Rarity.class(summoner);

    // Barbarian
    if (class == 1) {
      if (proficiencyReq == 1 || proficiencyReq == 2) {
        return true;
      } else if (
        proficiencyReq == 3 && Feats.armor_proficiency_heavy(summoner)
      ) {
        return true;
      } else if (proficiencyReq == 4 && armorType != 18) {
        return true;
      }

    // Bard, Ranger
    } else if (class == 2 || class == 8) {
      if (proficiencyReq == 1 || proficiencyReq == 2) {
        return true;
      } else if (
        (Feats.armor_proficiency_medium(summoner)) ||
        (proficiencyReq == 3 && Feats.armor_proficiency_heavy(summoner))
      ) {
        return true;
      } else if (proficiencyReq == 4 && armorType != 18) {
        return true;
      }

    // Cleric, Paladin
    } else if (class == 3 || class == 7) {
      if (proficiencyReq == 4 && armorType == 18) {
        return false;
      }
      return true;

    // Druid
    } else if (class == 4) {
      if (proficiencyReq == 1) {
        return true;
      } else if (proficiencyReq == 2) {
        // TODO: Filter out metal armor
        return true;
      } else if (
        proficiencyReq == 3 && Feats.armor_proficiency_heavy(summoner)
      ) {
        // TODO: Filter out metal armor. Is there any non-metal heavy?
        return true;
      } else if (proficiencyReq == 4 && armorType != 18) {
        // TODO: Filter out metal shields
        return true;
      }

    // Fighter
    } else if (class == 5) {
      return true;

    // Monk, Sorcerer, Wizard
    } else if (class == 6 || class == 10 || class == 11) {
      // TODO: Shield proficiency (63)
      return
        (proficiencyReq == 1 && Feats.armor_proficiency_light(summoner))
        || (proficiencyReq == 2 && Feats.armor_proficiency_medium(summoner))
        || (proficiencyReq == 3 && Feats.armor_proficiency_heavy(summoner));
    }

    return false;
  }

  function isProficientWithWeapon(uint256 summoner, uint256 weaponType)
    public
    view
    returns (bool)
  {
    uint256 class = Rarity.class(summoner);
    uint256 proficiency = CODEX_COMMON_WEAPONS.item_by_id(weaponType).proficiency;

    // Barbarian, Fighter, Paladin, Ranger
    if (class == 1 || class == 5 || class == 7 || class == 8) {
      if (proficiency == 1 || proficiency == 2) {
        return true;
      } else if (Feats.exotic_weapon_proficiency(summoner)) {
        return true;
      }

    // Bard
    } else if (class == 2) {
      if (proficiency == 1) {
        return true;
      } else if (
        (proficiency == 2 && Feats.martial_weapon_proficiency(summoner))
        || (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
      ) {
        return true;
      } else if (
        weaponType == 27      // longsword
        || weaponType == 29   // rapier
        || weaponType == 23   // sap
        || weaponType == 24   // short sword
        || weaponType == 46   // short bow
      ) {
        return true;
      }

    // Cleric, Sorcerer
    } else if (class == 3 || class == 10) {
      if (proficiency == 1) {
        return true;
      } else if (
        (proficiency == 2 && Feats.martial_weapon_proficiency(summoner))
        || (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
      ) {
        return true;
      }

    // Druid, Monk, Wizard
    } else if (class == 4 || class == 6 || class == 11) {
      if (
        (proficiency == 1 && Feats.simple_weapon_proficiency(summoner))
        || (proficiency == 2 && Feats.martial_weapon_proficiency(summoner))
        || (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
      ) {
        return true;

      // Druid
      } else if (
        class == 4 &&
        (weaponType == 6        // club
          || weaponType == 2    // dagger
          || weaponType == 15   // dart
          || weaponType == 11   // quarterstaff
          || weaponType == 30   // scimitar
          || weaponType == 5    // sickle
          || weaponType == 9    // shortspear
          || weaponType == 17   // sling
          || weaponType == 12)  // spear
      ) {
        return true;

      // Monk
      } else if (
        class == 6 &&
        (weaponType == 6        // club
          || weaponType == 14   // light crossbow
          || weaponType == 13   // heavy crossbow
          || weaponType == 2    // dagger
          || weaponType == 20   // hand axe
          || weaponType == 16   // javelin
          || weaponType == 48   // kama
          || weaponType == 49   // nunchaku
          || weaponType == 11   // quarterstaff
          || weaponType == 50   // sia
          || weaponType == 51   // siangham
          || weaponType == 17)  // sling
      ) {
        return true;

      // Wizard
      } else if (
        class == 11 &&
        (weaponType == 6        // club
          || weaponType == 2    // dagger
          || weaponType == 13   // heavy crossbow
          || weaponType == 14   // light crossbow
          || weaponType == 11)  // quarterstaff
      ) {
        return true;
      }
    }

    return false;
  }
}
