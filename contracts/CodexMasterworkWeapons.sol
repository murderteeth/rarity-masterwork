// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./core/interfaces/ICodexItemsWeapons.sol";

contract CodexMasterworkWeapons {
    string public constant index = "Items";
    string public constant class = "Masterwork Weapons";

    enum roll_type { STR, DEX, CON, INT, WIS, CHR, attack, initiative }

    struct effects_struct {
        int[8] roll_bonus;
    }

    codex_items_weapons constant commonWeaponsCodex =
        codex_items_weapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

    function get_proficiency_by_id(uint256 _id)
        public
        pure
        returns (string memory description)
    {
        return commonWeaponsCodex.get_proficiency_by_id(_id);
    }

    function get_encumbrance_by_id(uint256 _id)
        public
        pure
        returns (string memory description)
    {
        return commonWeaponsCodex.get_encumbrance_by_id(_id);
    }

    function get_damage_type_by_id(uint256 _id)
        public
        pure
        returns (string memory description)
    {
        return commonWeaponsCodex.get_damage_type_by_id(_id);
    }

    function item_by_id(uint256 _id)
        public
        pure
        returns (
            codex_items_weapons.weapon memory _weapon,
            effects_struct memory effects
            )
    {
        _weapon = commonWeaponsCodex.item_by_id(_id);
        _weapon.cost = _weapon.cost + 300e18;
        _weapon.name = string(abi.encodePacked("Masterwork ", _weapon.name));
        effects.roll_bonus[uint(roll_type.attack)] = 1;
    }
}