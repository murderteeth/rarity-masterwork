// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string public constant index = "Spells";
    string public constant class = "Cleric";
    string public constant school = "Abjuration";
    uint256 public constant level = 0;

    function spell_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool verbal,
            bool somatic,
            bool focus,
            bool divine_focus,
            uint256 xp_cost,
            uint256 time,
            uint256 range,
            uint256 duration,
            uint256 saving_throw_type,
            uint256 saving_throw_effect,
            bool spell_resistance,
            string memory description
        )
    {
        if (_id == 1) {
            return resistance();
        }
    }

    function resistance()
        public
        pure
        returns (
            uint256 id,
            string memory name,
            bool verbal,
            bool somatic,
            bool focus,
            bool divine_focus,
            uint256 xp_cost,
            uint256 time,
            uint256 range,
            uint256 duration,
            uint256 saving_throw_type,
            uint256 saving_throw_effect,
            bool spell_resistance,
            string memory description
        )
    {
        id = 1;
        name = "Resistance";
        verbal = true;
        somatic = true;
        focus = false;
        divine_focus = false;
        xp_cost = 0;
        time = 1;
        range = 1;
        duration = 60;
        saving_throw_type = 3;
        saving_throw_effect = 3;
        spell_resistance = true;
        description = "You imbue the subject with magical energy that protects it from harm, granting it a +1 resistance bonus on saves. Resistance can be made permanent with a permanency spell.";
    }
}
