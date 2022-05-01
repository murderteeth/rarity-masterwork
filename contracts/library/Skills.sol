//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexSkills.sol";
import "../interfaces/core/IRaritySkills.sol";

library Skills {
  IRarityCodexSkills private constant CODEX
    = IRarityCodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
  IRaritySkills private constant SKILLS 
    = IRaritySkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);

  function appraise(uint summoner) public view returns (uint8 ranks) {
    (uint id,,,,,,,) = CODEX.appraise();
    uint8[36] memory skills = SKILLS.get_skills(summoner);
    ranks = skills[id - 1];
  }

  function craft(uint summoner) public view returns (uint8 ranks) {
    (uint id,,,,,,,) = CODEX.craft();
    uint8[36] memory skills = SKILLS.get_skills(summoner);
    ranks = skills[id - 1];
  }

  function search(uint summoner) public view returns (uint8 ranks) {
    (uint id,,,,,,,) = CODEX.search();
    uint8[36] memory skills = SKILLS.get_skills(summoner);
    ranks = skills[id - 1];
  }

  function sense_motive(uint summoner) public view returns (uint8 ranks) {
    (uint id,,,,,,,) = CODEX.sense_motive();
    uint8[36] memory skills = SKILLS.get_skills(summoner);
    ranks = skills[id - 1];
  }
}