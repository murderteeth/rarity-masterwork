//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ISkills.sol";
import "../core/interfaces/IAttributes.sol";

library RaritySkillCheck {
    ISkills private constant SKILLS =
        ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    IAttributes private constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    function survival(uint256 summonerId) public view returns (int8) {
        int8 _survival = int8(SKILLS.get_skills(summonerId)[31]);
        (, , , , uint256 wisdom, ) = ATTRIBUTES.ability_scores(summonerId);
        return skillCheck(_survival, wisdom);
    }

    function senseMotive(uint256 summonerId) public view returns (int8) {
        int8 sm = int8(SKILLS.get_skills(summonerId)[27]);
        (, , , , uint256 wisdom, ) = ATTRIBUTES.ability_scores(summonerId);
        return skillCheck(sm, wisdom);
    }

    function skillCheck(int8 skill, uint256 ability)
        public
        pure
        returns (int8)
    {
        int8 _ability = int8(uint8(ability));
        return skill + attributeModifier(_ability);
    }

    function attributeModifier(int8 attribute) public pure returns (int8) {
        // Ints round toward zero, so 9 would otherwise be 0
        //   if we don't manually set it
        // Anything above 9 will calculate correctly, because
        //   modifiers round down (15 is 15-10/2 = 2.5 = +2 mod)
        if (attribute == 9) {
            return -1;
        }
        return (int8(attribute) - 10) / 2;
    }
}
