//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
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

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event SenseFarmersMotive(uint token, uint8 roll, uint8 score);

  struct Adventure {
    uint summoner;
    uint started;
    uint ended;
    bool farmers_bluff_checked;
    bool farmers_key;
  }

  mapping(uint => Adventure) public adventures;
  mapping(uint => uint) public active_adventures;

  function start(uint summoner) public approvedForSummoner(summoner) {
    require(active_adventures[summoner] == 0, "active_adventures[summoner] != 0");
    adventures[next_token].summoner = summoner;
    adventures[next_token].started = block.timestamp;
    active_adventures[summoner] = next_token;
    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function sense_farmers_motive(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require(adventure.ended == 0, "ended != 0");
    require(!adventure.farmers_bluff_checked, "farmers_bluff_checked == true");
 
    (uint8 roll, uint8 score) = SkillCheck.senseMotive(adventure.summoner);
    adventure.farmers_key = score >= FARMERS_KEY_DC;
    adventure.farmers_bluff_checked = true;
 
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