// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICodexItemsWeapons {
    struct weapon {
        uint256 id;
        uint256 cost;
        uint256 proficiency;
        uint256 encumbrance;
        uint256 damage_type;
        uint256 weight;
        uint256 damage;
        uint256 critical;
        int256 critical_modifier;
        uint256 range_increment;
        string name;
        string description;
    }

    function get_proficiency_by_id(uint256 _id)
        external
        pure
        returns (string memory description);

    function get_encumbrance_by_id(uint256 _id)
        external
        pure
        returns (string memory description);

    function get_damage_type_by_id(uint256 _id)
        external
        pure
        returns (string memory description);

    function item_by_id(uint256 _id)
        external
        pure
        returns (weapon memory _weapon);
}
