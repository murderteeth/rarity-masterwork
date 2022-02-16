//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ISkills.sol";
import "../core/interfaces/IAttributes.sol";
import "./RarityRandom.sol";

library RaritySkillCheck {
    ISkills private constant SKILLS =
        ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    IAttributes private constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    function senseMotive(uint256 summonerId, uint8 dc)
        public
        view
        returns (bool)
    {
        int32 sm = int32(int8(SKILLS.get_skills(summonerId)[27]));
        (, , , , uint32 wisdom, ) = ATTRIBUTES.ability_scores(summonerId);
        int32 roll = int32(int8(RarityRandom.dn(summonerId, dc, 20)));
        return (roll + skillCheck(sm, wisdom)) >= int8(dc);
    }

    function skillCheck(int32 skill, uint32 ability)
        public
        pure
        returns (int32)
    {
        // int32 _ability = int32(uint32(ability));
        return skill + attributeModifier(ability);
    }

    function attributeModifier(uint32 attribute) public pure returns (int32) {
        // Ints round toward zero, so 9 would otherwise be 0
        //   if we don't manually set it
        // Anything above 9 will calculate correctly, because
        //   modifiers round down (15 is 15-10/2 = 2.5 = +2 mod)
        if (attribute == 9) {
            return -1;
        }
        return (int32(attribute) - 10) / 2;
    }

    function baseDamage(uint32 str) public pure returns (uint32) {
        int32 _mod = attributeModifier(str);
        if (_mod <= 1) {
            return 1;
        } else {
            return uint32(_mod);
        }
    }

    function baseAttackBonusByClass(uint256 _class)
        public
        pure
        returns (uint32 attack)
    {
        if (_class == 1) {
            attack = 4;
        } else if (_class == 2) {
            attack = 3;
        } else if (_class == 3) {
            attack = 3;
        } else if (_class == 4) {
            attack = 3;
        } else if (_class == 5) {
            attack = 4;
        } else if (_class == 6) {
            attack = 3;
        } else if (_class == 7) {
            attack = 4;
        } else if (_class == 8) {
            attack = 4;
        } else if (_class == 9) {
            attack = 3;
        } else if (_class == 10) {
            attack = 2;
        } else if (_class == 11) {
            attack = 2;
        }
    }

    function baseAttackBonusByClassAndLevel(uint256 _class, uint256 _level)
        public
        pure
        returns (int32)
    {
        return
            int32(
                (int32(int256(_level)) *
                    int32(baseAttackBonusByClass(_class))) / 4
            );
    }

    function baseAttackBonus(
        uint256 _class,
        uint32 _str,
        uint256 _level
    ) public pure returns (int32) {
        return
            int32(baseAttackBonusByClassAndLevel(_class, _level)) +
            attributeModifier(_str);
    }
}
