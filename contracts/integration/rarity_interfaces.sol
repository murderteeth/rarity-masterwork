// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./rarity_structs.sol";

interface rarity_lib {
    function name(uint256 _s) external view returns (string memory);

    function base(uint256 _s) external view returns (rl._base memory);

    function description(uint256 _s) external view returns (string memory);

    function ability_scores(uint256 _s)
        external
        view
        returns (rl._ability_scores memory);

    function ability_modifiers(uint256 _s)
        external
        view
        returns (rl._ability_modifiers memory);

    function ability_scores_full(uint256 _s)
        external
        view
        returns (rl._ability_scores_full memory);

    function skills(uint256 _s) external view returns (rl._skills memory);

    function gold(uint256 _s) external view returns (rl._gold memory);

    function materials(uint256 _s)
        external
        view
        returns (rl._material[] memory);

    function summoner_full(uint256 _s)
        external
        view
        returns (rl._summoner memory);

    function summoners_full(uint256[] calldata _s)
        external
        view
        returns (rl._summoner[] memory);

    function items1(address _owner) external view returns (rl._item1[] memory);
}

interface rarity_manifested is IERC721 {
    function summoner(uint256 _summoner)
        external
        view
        returns (
            uint256 _xp,
            uint256 _log,
            uint256 _class,
            uint256 _level
        );

    function level(uint256) external view returns (uint256);

    function class(uint256) external view returns (uint256);

    function classes(uint256) external pure returns (string memory);
}

interface rarity_attributes {
    function ability_scores(uint256 _summoner)
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        );

    function abilities_by_level(uint256 _level) external view returns (uint256);

    function character_created(uint256 _summoner) external view returns (bool);
}

interface rarity_skills {
    function get_skills(uint256 _summoner)
        external
        view
        returns (uint8[36] memory);

    function skills_per_level(
        int256 _int,
        uint256 _class,
        uint256 _level
    ) external view returns (uint256 points);

    function calculate_points_for_set(uint256 _class, uint8[36] memory _skills)
        external
        view
        returns (uint256 points);

    function class_skills(uint256 _class)
        external
        view
        returns (bool[36] memory _skills);
}

interface rarity_fungible {
    event Transfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event Approval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(uint256 owner) external view returns (uint256);

    function allowance(uint256 owner, uint256 spender)
        external
        view
        returns (uint256);

    function approve(
        uint256 from,
        uint256 spender,
        uint256 amount
    ) external returns (bool);

    function transfer(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        uint256 executor,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}

interface rarity_gold is rarity_fungible {
    function claimed(uint256 _summoner) external view returns (uint256);
}

interface rarity_mat1 is rarity_fungible {
    function scout(uint256 _summoner) external view returns (uint256 reward);
}

interface rarity_item1 is IERC721Enumerable {
    function items(uint256)
        external
        view
        returns (
            uint8,
            uint8,
            uint32,
            uint256
        );
}

interface rarity_names is IERC721Enumerable {
    function summoner_name(uint256) external view returns (string memory);
}
