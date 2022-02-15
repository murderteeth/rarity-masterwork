//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IRarity.sol";
import "../core/interfaces/IAttributes.sol";
import "../core/interfaces/IMaterials.sol";

library RarityHelpers {
    IRarity public constant RM =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    IAttributes public constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    IMaterials public constant MATERIALS =
        IMaterials(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);

    function health(uint256 summonerId) public view returns (uint8) {
        uint256 _level = level(summonerId);
        uint256 _class = class(summonerId);
        (, , uint32 _const, , , ) = abilityScores(summonerId);
        return
            uint8(MATERIALS.health_by_class_and_level(_class, _level, _const));
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

    // Helpers
    function _isApprovedOrOwnerOfSummoner(uint256 _summonerId)
        internal
        view
        returns (bool)
    {
        return
            RM.getApproved(_summonerId) == msg.sender ||
            RM.ownerOf(_summonerId) == msg.sender ||
            RM.isApprovedForAll(RM.ownerOf(_summonerId), msg.sender);
    }
}
