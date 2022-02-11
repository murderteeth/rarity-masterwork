//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IRarity.sol";

library RarityOwnership {
    IRarity constant RM = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function rm() internal pure returns (IRarity) {
        return RM;
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
