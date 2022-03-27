//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Attributes.sol";
import "./Feats.sol";
import "./Random.sol";

library Roll {

  function initiative(uint summoner) public view returns (uint8 roll, int8 score) {
    (roll, score) = initiative(
      summoner, 
      Attributes.dexterityModifier(summoner), 
      Feats.improved_initiative(summoner) ? int8(4) : int8(0)
    );
  }

  function initiative(uint token, int8 total_dex_modifier, int8 initiative_bonus) public view returns (uint8 roll, int8 score) {
    roll = Random.dn(token, 11781769727069077443, 20);
    score = total_dex_modifier + int8(initiative_bonus) + int8(roll);
  }

}