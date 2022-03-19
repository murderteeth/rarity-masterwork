//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/core/IRarity.sol";

library Rarity {
  IRarity public constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

  function level(uint256 summoner) public view returns (uint256) {
    return RARITY.level(summoner);
  }

  function class(uint256 summoner) public view returns (uint256) {
    return RARITY.class(summoner);
  }

  function isApprovedOrOwnerOfSummoner(uint256 summoner) public view returns (bool) {
    return RARITY.getApproved(summoner) == msg.sender
      || RARITY.ownerOf(summoner) == msg.sender
      || RARITY.isApprovedForAll(RARITY.ownerOf(summoner), msg.sender);
  }
}