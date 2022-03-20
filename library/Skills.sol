//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexSkills.sol";
import "../interfaces/core/IRaritySkills.sol";

library Skills {
  IRarityCodexSkills private constant CODEX
    = IRarityCodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
  IRaritySkills private constant SKILLS 
    = IRaritySkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);

  function sense_motive(uint summoner) public view returns (uint8 points) {
    (uint id,,,,,,,) = CODEX.sense_motive();
    uint8[36] memory skills = SKILLS.get_skills(summoner);
    points = skills[id - 1];
  }
}