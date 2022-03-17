// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICodexItemsArmor {
    function item_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 proficiency,
            uint256 weight,
            uint256 armor_bonus,
            uint256 max_dex_bonus,
            int256 penalty,
            uint256 spell_failure,
            string memory name,
            string memory description
        );
}
