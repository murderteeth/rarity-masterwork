//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/core/IRaritySkills.sol";
import "../interfaces/core/IRarityAttributes.sol";
import "./Random.sol";
import "./Attributes.sol";
import "./Skills.sol";
import "./Feats.sol";

library SkillCheck {
  function senseMotive(uint summoner) public view returns (uint8 roll, uint8 score) {
    score = 1;

    int8 wisdomModifier = Attributes.wisdomModifier(summoner);
    if(wisdomModifier == -1) {
      score = 0;
    } else {
      score = score + uint8(wisdomModifier);
    }

    score = score + Skills.sense_motive(summoner);
    if(Feats.negotiator(summoner)) score = score + 2;
    roll = Random.dn(summoner, 3505325381439919961, 20);
    score = score + roll - 1;
  }
}