//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FeatCheck.sol";
import "./RarityBase.sol";
import "./Weapon.sol";

library Proficiency {
    /*
     * Barbarian 1
     *  Weapon 1, 2
     *  Armor 1, 2, 4 (except tower shield)
     * Bard 2
     *  Weapon 1 (and longsword, rapier, sap, short sword, shortbow, whip)
     *  Armor 1, 4 (except tower shield)
     * Cleric 3
     *  Weapon 1
     *  Armor 1, 2, 3, 4 (except tower shield)
     * Druid 4
     *  Weapon (club, dagger, dart, quarterstaff, scimitar, sickle, shortspear, sling, spear)
     *  Armor 1, 2 (except metal armor), 4 (except metal sheilds or tower shields)
     * Fighter 5
     *  Weapon 1, 2
     *  Armor 1, 2, 3, 4
     * Monk 6
     *  Weapon (club, crossbow light, crossbow heavy, dagger, handaxe, javelin, kama, nunchaku, quarterstaff, staff, shuriken, siangham, sling)
     *  Armor none
     * Paladin 7
     *  Weapon 1, 2
     *  Armor 1, 2, 3, 4 (except tower shields)
     * Ranger 8
     *  Weapon 1, 2
     *  Armor 1, 4 (except tower shields)
     * Rogue 9
     *  Weapon 1 (and hand crossbow, rapier, sap, shortbow, short sword)
     *  Armor 1
     * Sorcerer 10
     *  Weapon 1
     *  Armor none
     * Wizard 11
     *  Weapon (club, dagger, heavy crossbow, light crossbow, quarterstaff)
     *  Armor none
     */

    function isArmorProficient(
        uint256 summonerId,
        uint256 proficiencyReq,
        uint256 armorType
    ) public view returns (bool) {
        // TODO: Tower shield feat 96, armor type 18
        uint256 class = RarityBase.class(summonerId);
        if (class == 1) {
            // Barbarian
            if (proficiencyReq == 1 || proficiencyReq == 2) {
                return true;
            } else if (
                proficiencyReq == 3 && FeatCheck.armorHeavy(summonerId)
            ) {
                return true;
            } else if (proficiencyReq == 4 && armorType != 18) {
                return true;
            }
        } else if (class == 2 || class == 8) {
            // Bard, Ranger
            if (proficiencyReq == 1 || proficiencyReq == 2) {
                return true;
            } else if (
                (FeatCheck.armorMedium(summonerId)) ||
                (proficiencyReq == 3 && FeatCheck.armorHeavy(summonerId))
            ) {
                return true;
            } else if (proficiencyReq == 4 && armorType != 18) {
                return true;
            }
        } else if (class == 3 || class == 7) {
            // Cleric, Paladin
            if (proficiencyReq == 4 && armorType == 18) {
                return false;
            }
            return true;
        } else if (class == 4) {
            // Druid
            if (proficiencyReq == 1) {
                return true;
            } else if (proficiencyReq == 2) {
                // TODO: Filter out metal armor
                return true;
            } else if (
                proficiencyReq == 3 && FeatCheck.armorHeavy(summonerId)
            ) {
                // TODO: Filter out metal armor. Is there any non-metal heavy?
                return true;
            } else if (proficiencyReq == 4 && armorType != 18) {
                // TODO: Filter out metal shields
                return true;
            }
        } else if (class == 5) {
            // Fighter
            return true;
        } else if (class == 6 || class == 10 || class == 11) {
            // TODO: Shield proficiency (63)
            return
                (proficiencyReq == 1 && FeatCheck.armorLight(summonerId)) ||
                (proficiencyReq == 2 && FeatCheck.armorMedium(summonerId)) ||
                (proficiencyReq == 3 && FeatCheck.armorHeavy(summonerId));
        }

        return false;
    }

    function weaponBonus(uint256 summonerId, uint256 weaponType)
        public
        view
        returns (int8)
    {
        uint256 class = RarityBase.class(summonerId);
        uint256 proficiency = Weapon.fromCodex(weaponType).proficiency;
        if (class == 1 || class == 5 || class == 7 || class == 8) {
            // Barbarian, Fighter, Paladin, Ranger
            if (proficiency == 1 || proficiency == 2) {
                return 0;
            } else if (FeatCheck.exoticWeapon(summonerId) > 0) {
                return 0;
            }
        } else if (class == 2) {
            // Bard
            if (proficiency == 1) {
                return 0;
            } else if (
                (proficiency == 2 && FeatCheck.martialWeapon(summonerId) > 0) ||
                (proficiency == 3 && FeatCheck.exoticWeapon(summonerId) > 0)
            ) {
                return 0;
            } else if (
                weaponType == 27 || // longsword
                weaponType == 29 || // rapier
                weaponType == 23 || // sap
                weaponType == 24 || // short sword
                weaponType == 46 // short bow
            ) {
                return 0;
            }
        } else if (class == 3 || class == 10) {
            // Cleric, Sorcerer
            if (proficiency == 1) {
                return 0;
            } else if (
                (proficiency == 2 && FeatCheck.martialWeapon(summonerId) > 0) ||
                (proficiency == 3 && FeatCheck.exoticWeapon(summonerId) > 0)
            ) {
                return 0;
            }
        } else if (class == 4 || class == 6 || class == 11) {
            // Druid, Monk, Wizard
            if (
                (proficiency == 1 && FeatCheck.simpleWeapon(summonerId) > 0) ||
                (proficiency == 2 && FeatCheck.martialWeapon(summonerId) > 0) ||
                (proficiency == 3 && FeatCheck.exoticWeapon(summonerId) > 0)
            ) {
                return 0;
            } else if (
                class == 4 &&
                (weaponType == 6 || // club
                    weaponType == 2 || // dagger
                    weaponType == 15 || // dart
                    weaponType == 11 || // quarterstaff
                    weaponType == 30 || // scimitar
                    weaponType == 5 || // sickle
                    weaponType == 9 || // shortspear
                    weaponType == 17 || // sling
                    weaponType == 12) // spear
            ) {
                // Druid
                return 0;
            } else if (
                class == 6 &&
                (weaponType == 6 || // club
                    weaponType == 14 || // light crossbow
                    weaponType == 13 || // heavy crossbow
                    weaponType == 2 || // dagger
                    weaponType == 20 || // hand axe
                    weaponType == 16 || // javelin
                    weaponType == 48 || // kama
                    weaponType == 49 || // nunchaku
                    weaponType == 11 || // quarterstaff
                    weaponType == 50 || // sia
                    weaponType == 51 || // siangham
                    weaponType == 17) // sling
            ) {
                // Monk
                return 0;
            } else if (
                class == 11 &&
                (weaponType == 6 || // club
                    weaponType == 2 || // dagger
                    weaponType == 13 || // heavy crossbow
                    weaponType == 14 || // light crossbow
                    weaponType == 11) // quarterstaff
            ) {
                // Wizard
                return 0;
            }
        }

        return -4;
    }
}
