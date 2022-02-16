//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IAttributes.sol";

library Attributes {
    IAttributes private constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    struct Abilities {
        uint256 strength;
        uint256 dexterity;
        uint256 constitution;
        uint256 intelligence;
        uint256 wisdom;
        uint256 charisma;
    }

    function abilityScores(uint256 summonerId)
        public
        view
        returns (Abilities memory)
    {
        (
            uint256 str,
            uint256 dex,
            uint256 con,
            uint256 _int,
            uint256 wis,
            uint256 cha
        ) = ATTRIBUTES.ability_scores(summonerId);
        return Abilities(str, dex, con, _int, wis, cha);
    }

    function strengthModifier(uint256 summonerId) public view returns (int8) {
        return computeModifier(abilityScores(summonerId).strength);
    }

    function dexterityModifier(uint256 summonerId) public view returns (int8) {
        return computeModifier(abilityScores(summonerId).dexterity);
    }

    function computeModifier(uint256 ability) public pure returns (int8) {
        if (ability < 10) return -1;
        return (int8(int256(ability)) - 10) / 2;
    }
}
