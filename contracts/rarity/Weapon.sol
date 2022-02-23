//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ICodexItemsWeapons.sol";

library Weapon {
    codex_items_weapons public constant WEAPON_CODEX =
        codex_items_weapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

    function fromCodex(uint256 itemType)
        public
        pure
        returns (codex_items_weapons.weapon memory)
    {
        return WEAPON_CODEX.item_by_id(itemType);
    }
}
