//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IFeats.sol";

library FeatCheck {
    IFeats private constant FEATS =
        IFeats(0x51C0B29A1d84611373BA301706c6B4b72283C80F);

    function initiative(uint256 summonerId) public view returns (uint8) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        if (feats[64]) {
            return 4;
        } else {
            return 0;
        }
    }
}
