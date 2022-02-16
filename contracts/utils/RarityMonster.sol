//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RarityRandom.sol";

library RarityMonster {
    function hp(
        uint8 rolls,
        uint8 sides,
        uint8 bonus
    ) public view returns (uint8) {
        uint8 total = bonus;
        for (uint8 i = 0; i < rolls; i++) {
            uint8 roll = RarityRandom.dn(0, i, sides);
            total += roll;
        }
        return total;
    }
}
