// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRarityCodexMasterworkArmor {
    function class() external view returns (string memory);

    function get_proficiency_by_id(uint256 _id)
        external
        pure
        returns (string memory description);

    function index() external view returns (string memory);

    function item_by_id(uint256 _id)
        external
        pure
        returns (IArmor.Armor memory armor);
}

interface IArmor {
    struct Armor {
        uint8 id;
        uint8 proficiency;
        uint8 weight;
        uint8 armor_bonus;
        uint8 max_dex_bonus;
        int8 penalty;
        uint8 spell_failure;
        uint256 cost;
        string name;
        string description;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"get_proficiency_by_id","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"item_by_id","outputs":[{"components":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"uint8","name":"proficiency","type":"uint8"},{"internalType":"uint8","name":"weight","type":"uint8"},{"internalType":"uint8","name":"armor_bonus","type":"uint8"},{"internalType":"uint8","name":"max_dex_bonus","type":"uint8"},{"internalType":"int8","name":"penalty","type":"int8"},{"internalType":"uint8","name":"spell_failure","type":"uint8"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"internalType":"struct IArmor.Armor","name":"armor","type":"tuple"}],"stateMutability":"pure","type":"function"}]
*/
