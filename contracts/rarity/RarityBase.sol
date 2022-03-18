//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IRarity.sol";

library RarityBase {
    IRarity public constant RM =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function isApprovedOrOwnerOfSummoner(uint256 _summonerId)
        public
        view
        returns (bool)
    {
        return
            RM.getApproved(_summonerId) == msg.sender ||
            RM.ownerOf(_summonerId) == msg.sender ||
            RM.isApprovedForAll(RM.ownerOf(_summonerId), msg.sender);
    }

    function level(uint256 summonerId) public view returns (uint256) {
        return RM.level(summonerId);
    }

    function class(uint256 summonerId) public view returns (uint256) {
        return RM.class(summonerId);
    }
}
