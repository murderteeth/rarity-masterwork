//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Attributes.sol";
import "./Random.sol";

library Monster {
    /*
     * Monster initiative is a simple roll with their dexterity modifier and any bonuses
     * as described in their stat sheet
     */
    function initiative(uint8 dex, int8 bonus) public view returns (int8) {
        int8 dMod = Attributes.computeModifier(dex);
        uint8 roll = Random.dn(8, 9, 20);
        return int8(roll) + int8(dMod) + bonus;
    }

    /*
     * Monster health is usually given in the format "1d8 (4 hp)"
     * This means 1 roll of a dice with 8 sides plus 4hp
     */
    function hp(
        uint8 rolls,
        uint8 sides,
        uint8 bonus
    ) public view returns (uint8) {
        uint8 total = bonus;
        for (uint8 i = 0; i < rolls; i++) {
            uint8 roll = Random.dn(0, i, sides);
            total += roll;
        }
        return total;
    }

    /*
     * This is a basic attack that only does physical damage
     * It is usually given in the form of (1d6-1 /x3)
     * This means 1 dice, 6 sides, minus 1 repeated 3 times
     */
    function basicAttack(
        uint8 attackBonus,
        uint8 weaponBonus,
        uint8 ac,
        uint8 rolls,
        uint8 sides,
        int8 mod,
        uint8 times
    )
        public
        view
        returns (
            uint8 attackRoll,
            uint8 attackScore,
            uint8 damage
        )
    {
        attackRoll = Random.dn(ac, 0, 20);
        attackScore = attackRoll + attackBonus + weaponBonus;
        damage = 0;

        if (attackRoll == 1) {
            return (attackRoll, attackScore, damage);
        }

        if (attackRoll == 20 || attackScore >= ac) {
            for (uint256 j = 0; j < times; j++) {
                for (uint8 i = 0; i < rolls; i++) {
                    int8 roll = int8(Random.dn(4, i, sides));
                    int8 total = roll + mod;
                    if (total > 0) {
                        damage += uint8(total);
                    }
                }
            }
        }
    }
}
