// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface codex_items_weapons {
    struct weapon {
        uint id;
        uint cost;
        uint proficiency;
        uint encumbrance;
        uint damage_type;
        uint weight;
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment;
        string name;
        string description;
    }

    function get_proficiency_by_id(uint _id) external pure returns (string memory description);
    function get_encumbrance_by_id(uint _id) external pure returns (string memory description);
    function get_damage_type_by_id(uint _id) external pure returns (string memory description);
    function item_by_id(uint _id) external pure returns(weapon memory _weapon);
}