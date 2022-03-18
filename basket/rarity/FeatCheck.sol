//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/IFeats.sol";

library FeatCheck {
    IFeats private constant FEATS =
        IFeats(0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a);

    function initiative(uint256 summonerId) public view returns (uint8) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        // Per the first codex, improved initiative is ID 59
        // https://ftmscan.com/address/0x88db734E9f64cA71a24d8e75986D964FFf7a1E10#code
        if (feats[59]) {
            return 4;
        } else {
            return 0;
        }
    }

    function armorLight(uint256 summonerId) public view returns (bool) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        return feats[5];
    }

    function armorMedium(uint256 summonerId) public view returns (bool) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        return feats[6];
    }

    function armorHeavy(uint256 summonerId) public view returns (bool) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        return feats[7];
    }

    function simpleWeapon(uint256 summonerId) public view returns (uint8) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        if (feats[91]) {
            return 4;
        } else {
            return 0;
        }
    }

    function martialWeapon(uint256 summonerId) public view returns (uint8) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        if (feats[75]) {
            return 4;
        } else {
            return 0;
        }
    }

    function exoticWeapon(uint256 summonerId) public view returns (uint8) {
        bool[100] memory feats = FEATS.get_feats(summonerId);
        if (feats[34]) {
            return 4;
        } else {
            return 0;
        }
    }
}
