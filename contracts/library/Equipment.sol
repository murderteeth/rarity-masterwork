//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarityEquipment {
  function slots(uint summoner, uint slot_type) external view returns (Equipment.Slot memory);
  function encumberance(uint summoner) external view returns (uint);
  function codexes(address mint, uint base_type) external view returns (address);
  function equip(uint summoner, uint slot_type, address mint, address codex, uint token) external;
  function unequip(uint summoner, uint slot_type) external;
  function snapshot(uint token, uint summoner) external;
  function snapshots(address encounter, uint token, uint summoner, uint slot_type) external view returns (Equipment.Slot memory);
}

library Equipment {
  struct Slot {
    address mint;
    uint token;
  }

  uint8 public constant SLOT_TYPE_WEAPON_1 = 1;
  uint8 public constant SLOT_TYPE_ARMOR = 2;
  uint8 public constant SLOT_TYPE_SHIELD = 3;
  uint8 public constant SLOT_TYPE_WEAPON_2 = 4;
  uint8 public constant SLOT_TYPE_HANDS = 5;
  uint8 public constant SLOT_TYPE_RING_1 = 6;
  uint8 public constant SLOT_TYPE_RING_2 = 7;
  uint8 public constant SLOT_TYPE_HEAD = 8;
  uint8 public constant SLOT_TYPE_HEADBAND = 9;
  uint8 public constant SLOT_TYPE_EYES = 10;
  uint8 public constant SLOT_TYPE_NECK = 11;
  uint8 public constant SLOT_TYPE_SHOULDERS = 12;
  uint8 public constant SLOT_TYPE_CHEST = 13;
  uint8 public constant SLOT_TYPE_BELT = 14;
  uint8 public constant SLOT_TYPE_BODY = 15;
  uint8 public constant SLOT_TYPE_ARMS = 16;
  uint8 public constant SLOT_TYPE_FEET = 17;
}