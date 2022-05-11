// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library rl {
    struct _base {
        string name;
        uint256 xp;
        uint256 log;
        uint256 class;
        uint256 level;
    }

    struct _ability_scores {
        uint32 _str;
        uint32 _dex;
        uint32 _con;
        uint32 _int;
        uint32 _wis;
        uint32 _cha;
    }

    struct _ability_modifiers {
        int32 _str;
        int32 _dex;
        int32 _con;
        int32 _int;
        int32 _wis;
        int32 _cha;
    }

    struct _ability_scores_full {
        _ability_scores attributes;
        _ability_modifiers modifiers;
        uint256 total_points;
        uint256 spent_points;
        bool created;
    }

    struct _skills {
        uint8[36] skills;
        bool[36] class_skills;
        uint256 total_points;
        uint256 spent_points;
    }

    struct _gold {
        uint256 balance;
        uint256 claimed;
        uint256 claimable;
    }

    struct _material {
        uint256 balance;
        uint256 scout;
    }

    struct _summoner {
        _base base;
        _ability_scores_full ability_scores;
        _skills skills;
        _gold gold;
        _material[] materials;
    }

    struct _item1 {
        uint8 base_type;
        uint8 item_type;
        uint32 crafted;
        uint256 crafter;
    }
}
