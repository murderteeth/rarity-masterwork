//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/core/IRarityAttributes.sol";

library Attributes {
  IRarityAttributes private constant ATTRIBUTES 
    = IRarityAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

  struct Abilities {
    uint32 strength;
    uint32 dexterity;
    uint32 constitution;
    uint32 intelligence;
    uint32 wisdom;
    uint32 charisma;
  }

  function strengthModifier(uint256 summoner) public view returns (int8) {
    (uint32 strength,,,,,) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(strength);
  }

  function dexterityModifier(uint256 summoner) public view returns (int8) {
    (, uint32 dexterity,,,,) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(dexterity);
  }

  function constitutionModifier(uint256 summoner) public view returns (int8) {
    (,, uint32 constitution,,,) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(constitution);
  }

  function intelligenceModifier(uint256 summoner) public view returns (int8) {
    (,,, uint32 intelligence,,) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(intelligence);
  }

  function wisdomModifier(uint256 summoner) public view returns (int8) {
    (,,,, uint32 wisdom,) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(wisdom);
  }

  function charismaModifier(uint256 summoner) public view returns (int8) {
    (,,,,, uint32 charisma) = ATTRIBUTES.ability_scores(summoner);
    return computeModifier(charisma);
  }

  function computeModifier(uint32 ability) public pure returns (int8) {
    if (ability < 10) return -1;
    return (int8(int32(ability)) - 10) / 2;
  }
}