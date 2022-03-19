//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../library/ForSummoners.sol";

contract rarity_adventure_2 is ERC721Enumerable, ForSummoners {
  uint public next_token = 1;
  uint private constant DAY = 1 days;
  uint8 public constant SENSE_MOTIVE_DC = 15;

  int8 public constant MONSTER_INITIATIVE_BONUS = 1;
  uint8 public constant MONSTER_AC = 15;
  uint8 public constant MONSTER_HIT_DICE_ROLLS = 1;
  uint8 public constant MONSTER_HIT_DICE_SIDES = 8;
  uint8 public constant MONSTER_HIT_DICE_BONUS = 4;
  uint8 public constant MONSTER_DEX = 13;

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  struct Adventure {
    uint summoner;
    uint startedOn;
    uint endedOn;
  }

  mapping(uint => Adventure) public adventures;
  mapping(uint => uint) public activeAdventures;

  function start(uint summoner) public approvedForSummoner(summoner) {
    require(activeAdventures[summoner] == 0, "activeAdventures[summoner] != 0");
    adventures[next_token].summoner = summoner;
    adventures[next_token].startedOn = block.timestamp;
    activeAdventures[summoner] = next_token;
    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function isApprovedOrOwnerOfAdventure(uint adventure) public view returns (bool) {
    return getApproved(adventure) == msg.sender
      || ownerOf(adventure) == msg.sender
      || isApprovedForAll(ownerOf(adventure), msg.sender);
  }

  modifier approvedForAdventure(uint adventure) {
    if (isApprovedOrOwnerOfAdventure(adventure)) {
      _;
    } else {
      revert("!approvedForAdventure");
    }
  }

  // TODO: tokenURI

}