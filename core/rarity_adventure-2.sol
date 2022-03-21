//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../library/ForSummoners.sol";
import "../library/SkillCheck.sol";

contract rarity_adventure_2 is ERC721Enumerable, ForSummoners {
  uint public next_token = 1;
  uint private constant DAY = 1 days;
  uint public constant SENSE_MOTIVE_XP_COST = 347e15;  // ~ 2 minutes of xp
  uint8 public constant FARMERS_KEY_DC = 20;

  int8 public constant MONSTER_INITIATIVE_BONUS = 1;
  uint8 public constant MONSTER_AC = 15;
  uint8 public constant MONSTER_HIT_DICE_ROLLS = 1;
  uint8 public constant MONSTER_HIT_DICE_SIDES = 8;
  uint8 public constant MONSTER_HIT_DICE_BONUS = 4;
  uint8 public constant MONSTER_DEX = 13;

  IRarity public constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event SenseFarmersMotive(uint token, uint8 roll, uint8 score);

  struct Adventure {
    bool farmersKey;
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

  function sense_farmers_motive(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require(adventure.endedOn == 0, "adventure.endedOn != 0");
    (uint8 roll, uint8 score) = SkillCheck.senseMotive(adventure.summoner);
    if(!adventure.farmersKey && score >= FARMERS_KEY_DC) {
      adventure.farmersKey = true;
    }
    RARITY.spend_xp(adventure.summoner, SENSE_MOTIVE_XP_COST);
    emit SenseFarmersMotive(token, roll, score);
  }

  // TODO: tokenURI

  function isApprovedOrOwnerOfAdventure(uint token) public view returns (bool) {
    return getApproved(token) == msg.sender
      || ownerOf(token) == msg.sender
      || isApprovedForAll(ownerOf(token), msg.sender);
  }

  modifier approvedForAdventure(uint token) {
    if (isApprovedOrOwnerOfAdventure(token)) {
      _;
    } else {
      revert("!approvedForAdventure");
    }
  }

}