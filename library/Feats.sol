//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexFeats1.sol";
import "../interfaces/codex/IRarityCodexFeats2.sol";
import "../interfaces/core/IRarityFeats.sol";

library Feats {
  IRarityCodexFeats1 private constant CODEX1 
    = IRarityCodexFeats1(0x88db734E9f64cA71a24d8e75986D964FFf7a1E10);
  IRarityCodexFeats2 private constant CODEX2 
    = IRarityCodexFeats2(0x7A4Ba2B077CD9f4B13D5853411EcAE12FADab89C);
  IRarityFeats private constant FEATS 
    = IRarityFeats(0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a);

  function improved_initiative(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX1.improved_initiative();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function armor_proficiency_light(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX1.armor_proficiency_light();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function armor_proficiency_medium(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX1.armor_proficiency_medium();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function armor_proficiency_heavy(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX1.armor_proficiency_heavy();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function simple_weapon_proficiency(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX2.simple_weapon_proficiency();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function martial_weapon_proficiency(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX2.martial_weapon_proficiency();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function exotic_weapon_proficiency(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX1.exotic_weapon_proficiency();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }

  function negotiator(uint256 summoner) public view returns (bool) {
    (uint id,,,,,,) = CODEX2.negotiator();
    bool[100] memory feats = FEATS.get_feats(summoner);
    return feats[id - 1];
  }
}