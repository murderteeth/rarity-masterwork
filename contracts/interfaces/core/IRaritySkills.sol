// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRaritySkills {
    function base_per_class(uint256 _class)
        external
        pure
        returns (uint256 base);

    function calculate_points_for_set(uint256 _class, uint8[36] memory _skills)
        external
        pure
        returns (uint256 points);

    function class_skills(uint256 _class)
        external
        pure
        returns (bool[36] memory _skills);

    function class_skills_by_name(uint256 _class)
        external
        view
        returns (string[] memory);

    function get_skills(uint256 _summoner)
        external
        view
        returns (uint8[36] memory);

    function is_valid_set(uint256 _summoner, uint8[36] memory _skills)
        external
        view
        returns (bool);

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function set_skills(uint256 _summoner, uint8[36] memory _skills) external;

    function skills(uint256, uint256) external view returns (uint8);

    function skills_per_level(
        int256 _int,
        uint256 _class,
        uint256 _level
    ) external pure returns (uint256 points);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"base_per_class","outputs":[{"internalType":"uint256","name":"base","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"calculate_points_for_set","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills","outputs":[{"internalType":"bool[36]","name":"_skills","type":"bool[36]"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills_by_name","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_skills","outputs":[{"internalType":"uint8[36]","name":"","type":"uint8[36]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"is_valid_set","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"set_skills","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"skills","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"int256","name":"_int","type":"int256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"skills_per_level","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/
