// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface codex_items_armor {
    struct armor {
        uint256 id;
        uint256 cost;
        uint256 proficiency;
        uint256 weight;
        uint256 armor_bonus;
        uint256 max_dex_bonus;
        int256 penalty;
        uint256 spell_failure;
        string name;
        string description;
    }

    function item_by_id(uint256 _id)
        external
        pure
        returns (armor memory _armor);
}
