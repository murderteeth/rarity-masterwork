//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Crafting.sol";
import "../library/SkillCheck.sol";

contract rarity_adventure_2 is ERC721Enumerable, IERC721Receiver, ForSummoners, ForItems {
  uint public next_token = 1;
  uint private constant DAY = 1 days;
  uint8 public constant FARMERS_KEY_DC = 20;
  uint8 public constant EQUIPMENT_SLOTS = 2;
  uint8 public constant EQUIPMENT_TYPE_WEAPON = 0;
  uint8 public constant EQUIPMENT_TYPE_ARMOR = 1;

  int8 public constant MONSTER_INITIATIVE_BONUS = 1;
  uint8 public constant MONSTER_AC = 15;
  uint8 public constant MONSTER_HIT_DICE_ROLLS = 1;
  uint8 public constant MONSTER_HIT_DICE_SIDES = 8;
  uint8 public constant MONSTER_HIT_DICE_BONUS = 4;
  uint8 public constant MONSTER_DEX = 13;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event SenseFarmersMotive(uint token, uint8 roll, uint8 score);

  struct EquipmentSlot {
    address item_contract;
    uint item;
  }

  struct Adventure {
    uint summoner;
    uint started;
    uint ended;
    bool farmers_bluff_challenged;
    bool farmers_key;
  }

  mapping(uint => Adventure) public adventures;
  mapping(uint => uint) public active_adventures;
  mapping(uint => EquipmentSlot[EQUIPMENT_SLOTS]) public equipment_slots;
  mapping(address => mapping(uint => uint)) public equipment_index;

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator; from; tokenId; data; // lint silencio!
    return this.onERC721Received.selector;
  }

  function start(uint summoner) public approvedForSummoner(summoner) {
    require(active_adventures[summoner] == 0, "active_adventures[summoner] != 0");
    adventures[next_token].summoner = summoner;
    adventures[next_token].started = block.timestamp;
    active_adventures[summoner] = next_token;
    RARITY.safeTransferFrom(msg.sender, address(this), summoner);
    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function sense_farmers_motive(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require(adventure.ended == 0, "ended != 0");
    require(!adventure.farmers_bluff_challenged, "farmers_bluff_challenged == true");
    (uint8 roll, uint8 score) = SkillCheck.senseMotive(adventure.summoner);
    adventure.farmers_key = score >= FARMERS_KEY_DC;
    adventure.farmers_bluff_challenged = true;
    emit SenseFarmersMotive(token, roll, score);
  }

  function equip(
    uint token,
    uint8 equipment_type,
    address item_contract, 
    uint item
    ) public 
    approvedForAdventure(token)
    approvedForItem(item_contract, item)
  {
    require(equipment_type < 2, "!equipment_type");

    (uint8 base_type, uint8 item_type,,) = ICrafting(item_contract).items(item);
    if(equipment_type == EQUIPMENT_TYPE_WEAPON) {
      require(base_type == 3, "!weapon");
    } else if(equipment_type == EQUIPMENT_TYPE_ARMOR) {
      require(base_type == 2 && item_type < 13, "!armor");
    }

    EquipmentSlot storage slot = equipment_slots[token][equipment_type];
    if(item_contract != slot.item_contract || item != slot.item) {
      if(slot.item_contract != address(0)) {
        ICrafting(slot.item_contract).safeTransferFrom(address(this), msg.sender, slot.item);
        delete equipment_index[slot.item_contract][slot.item];
      }
      if(item_contract != address(0)) {
        require(equipment_index[item_contract][item] == 0, "!item available");
        ICrafting(item_contract).safeTransferFrom(msg.sender, address(this), item);
        slot.item_contract = item_contract;
        slot.item = item;
        equipment_index[item_contract][item] = token;
      } else {
        delete slot.item_contract;
        delete slot.item;
      }
    }
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