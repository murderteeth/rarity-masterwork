// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICodexItemsTools {
    struct effects_struct {
        int[36] skill_bonus;
    }

    function item_by_id(uint _id) external pure returns(
        uint8 id,
        uint cost,
        uint weight,
        string memory name,
        string memory description,
        effects_struct memory effects
    );

    function artisans_tools() external pure returns (
        uint8 id,
        uint cost,
        uint weight,
        string memory name,
        string memory description,
        effects_struct memory effects
    );

}
