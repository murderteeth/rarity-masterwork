//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarityEquipment {
  function slots(uint summoner, uint slot_type) external view returns (Equipment.Slot memory);
  function encumberance(uint summoner) external view returns (uint);
  function codexes(address mint, uint base_type) external view returns (address);
  function equip(uint summoner, uint slot_type, address mint, address codex, uint token) external;
  function unequip(uint summoner, uint slot_type) external;
}

library Equipment {
  struct Slot {
    address mint;
    uint token;
  }

  uint8 public constant SLOT_TYPE_WEAPON_1 = 0;
  uint8 public constant SLOT_TYPE_ARMOR = 1;
  uint8 public constant SLOT_TYPE_SHIELD = 2;
  uint8 public constant SLOT_TYPE_WEAPON_2 = 3;
  uint8 public constant SLOT_TYPE_HANDS = 4;
  uint8 public constant SLOT_TYPE_RING_1 = 5;
  uint8 public constant SLOT_TYPE_RING_2 = 6;
  uint8 public constant SLOT_TYPE_HEAD = 7;
  uint8 public constant SLOT_TYPE_HEADBAND = 8;
  uint8 public constant SLOT_TYPE_EYES = 9;
  uint8 public constant SLOT_TYPE_NECK = 10;
  uint8 public constant SLOT_TYPE_SHOULDERS = 11;
  uint8 public constant SLOT_TYPE_CHEST = 12;
  uint8 public constant SLOT_TYPE_BELT = 13;
  uint8 public constant SLOT_TYPE_BODY = 14;
  uint8 public constant SLOT_TYPE_ARMS = 15;
  uint8 public constant SLOT_TYPE_FEET = 16;
}