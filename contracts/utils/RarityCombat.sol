//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IRarity.sol";
import "../core/interfaces/IAttributes.sol";
import "../core/interfaces/IMaterials.sol";

library RarityCombat {
    IRarity public constant RM =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    IAttributes public constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    function summonerHp(uint256 summonerId) public view returns (uint8) {
        uint256 _level = level(summonerId);
        uint256 _class = class(summonerId);
        (, , uint32 _const, , , ) = abilityScores(summonerId);
        return uint8(healthByClassAndLevel(_class, _level, _const));
    }

    function abilityScores(uint256 summonerId)
        public
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        return ATTRIBUTES.ability_scores(summonerId);
    }

    function level(uint256 summonerId) public view returns (uint256) {
        return RM.level(summonerId);
    }

    function class(uint256 summonerId) public view returns (uint256) {
        return RM.class(summonerId);
    }

    function healthByClass(uint256 _class)
        public
        pure
        returns (uint256 health)
    {
        if (_class == 1) {
            health = 12;
        } else if (_class == 2) {
            health = 6;
        } else if (_class == 3) {
            health = 8;
        } else if (_class == 4) {
            health = 8;
        } else if (_class == 5) {
            health = 10;
        } else if (_class == 6) {
            health = 8;
        } else if (_class == 7) {
            health = 10;
        } else if (_class == 8) {
            health = 8;
        } else if (_class == 9) {
            health = 6;
        } else if (_class == 10) {
            health = 4;
        } else if (_class == 11) {
            health = 4;
        }
    }

    function healthByClassAndLevel(
        uint256 _class,
        uint256 _level,
        uint32 _const
    ) public pure returns (uint256 health) {
        int256 _mod = computeModifier(_const);
        int256 _base_health = int256(healthByClass(_class)) + _mod;
        if (_base_health <= 0) {
            _base_health = 1;
        }
        health = uint256(_base_health) * _level;
    }

    function computeModifier(uint256 ability) internal pure returns (int256) {
        if (ability < 10) return -1;
        return (int256(ability) - 10) / 2;
    }
}
