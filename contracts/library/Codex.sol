//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWeapon {
  struct Weapon {
    uint8 id;
    uint8 proficiency;
    uint8 encumbrance;
    uint8 damage_type;
    uint8 weight;
    uint8 damage;
    uint8 critical;
    int8 critical_modifier;
    uint8 range_increment;
    uint cost;
    string name;
    string description;
  }

  function get_weapon(uint8 item_type) external view returns (Weapon memory);
}

interface ICodexWeapon {
  function item_by_id(uint id) external pure returns(IWeapon.Weapon memory);
  function get_proficiency_by_id(uint id) external pure returns (string memory description);
  function get_encumbrance_by_id(uint id) external pure returns (string memory description);
  function get_damage_type_by_id(uint id) external pure returns (string memory description);
}

interface IArmor {
  struct Armor {
    uint8 id;
    uint8 proficiency;
    uint8 weight;
    uint8 armor_bonus;
    uint8 max_dex_bonus;
    int8 penalty;
    uint8 spell_failure;
    uint cost;
    string name;
    string description;
  }

  function get_armor(uint8 item_type) external view returns (Armor memory);
}

interface ICodexArmor {
  function item_by_id(uint id) external pure returns(IArmor.Armor memory);
  function get_proficiency_by_id(uint id) external pure returns (string memory description);
}

interface ITools {
  struct Tools {
    uint8 id;
    uint8 weight;
    uint cost;
    string name;
    string description;
    int8[36] skill_bonus;
  }

  function get_tools(uint8 item_type) external view returns (Tools memory);
}

interface ICodexTools {
  function item_by_id(uint id) external pure returns(ITools.Tools memory);
}