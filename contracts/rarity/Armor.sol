//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ICrafting.sol";
import "../core/interfaces/ICodexItemsArmor.sol";
import "./Attributes.sol";
import "./Proficiency.sol";

library Armor {
    codex_items_armor internal constant ARMOR_CODEX =
        codex_items_armor(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);

    function class(
        uint256 summonerId,
        uint256 armorId,
        ICrafting armorContract
    ) public view returns (uint8) {
        // TODO: Monks should get a wisdom bonus and level bonus
        // http://www.d20srd.org/srd/classes/monk.htm

        (, uint256 itemType, , ) = armorContract.items(armorId);

        (, , , , uint256 armorBonus, uint256 maxDexBonus, , , , ) = ARMOR_CODEX
            .item_by_id(itemType);

        int8 dexModifier = Attributes.dexterityModifier(summonerId);

        int8 result = 10 + int8(uint8(armorBonus));
        if (dexModifier > int256(maxDexBonus)) {
            result += int8(uint8(maxDexBonus));
        } else {
            result += dexModifier;
        }
        return uint8(result);
    }

    /*
     * If not proficient, a penalty (negative bonus)
     * is applied to attack rolls and any str or dex ability/skill checks.
     */
    function proficiencyBonus(
        uint256 summonerId,
        uint256 armorId,
        ICrafting armorContract
    ) public view returns (int8) {
        (, uint256 itemType, , ) = armorContract.items(armorId);
        (, , uint256 _proficiency, , , , int256 penalty, , , ) = ARMOR_CODEX
            .item_by_id(itemType);

        if (
            !Proficiency.isArmorProficient(summonerId, _proficiency, itemType)
        ) {
            return int8(penalty);
        } else {
            return 0;
        }
    }
}
