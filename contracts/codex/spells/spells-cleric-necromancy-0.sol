// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string public constant index = "Spells";
    string public constant class = "Cleric";
    string public constant school = "Necromancy";
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
        if (_id == 9) {
            return inflict_minor_wounds();
        }
    }

    function inflict_minor_wounds()
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
        id = 9;
        name = "Inflict Minor Wounds";
        verbal = true;
        somatic = true;
        focus = false;
        divine_focus = false;
        xp_cost = 0;
        time = 1;
        range = 1;
        duration = 0;
        saving_throw_type = 3;
        saving_throw_effect = 3;
        spell_resistance = true;
        description = "This spell functions like inflict light wounds, except that you deal 1 point of damage and a Will save negates the damage instead of halving it.";
    }
}
