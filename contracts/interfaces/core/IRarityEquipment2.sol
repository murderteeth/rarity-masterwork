// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityEquipment2 {
    event Equip(
        address indexed owner,
        uint256 indexed summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    );
    event Unequip(
        address indexed owner,
        uint256 indexed summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    );

    function MINT_WHITELIST(uint256) external view returns (address);

    function codexes(address, uint256) external view returns (address);

    function encumberance(uint256) external view returns (uint256);

    function equip(
        uint256 summoner,
        uint8 slot_type,
        address mint,
        uint256 token
    ) external;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function set_mint_whitelist(
        address common,
        address common_armor_codex,
        address common_weapon_codex,
        address masterwork,
        address masterwork_armor_codex,
        address masterwork_weapon_codex
    ) external;

    function slots(uint256, uint8)
        external
        view
        returns (address mint, uint256 token);

    function snapshot(uint256 token, uint256 summoner) external;

    function snapshots(
        address,
        uint256,
        uint256,
        uint8
    ) external view returns (address mint, uint256 token);

    function unequip(uint256 summoner, uint8 slot_type) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint8","name":"slot_type","type":"uint8"},{"indexed":false,"internalType":"address","name":"mint","type":"address"},{"indexed":false,"internalType":"uint256","name":"token","type":"uint256"}],"name":"Equip","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint8","name":"slot_type","type":"uint8"},{"indexed":false,"internalType":"address","name":"mint","type":"address"},{"indexed":false,"internalType":"uint256","name":"token","type":"uint256"}],"name":"Unequip","type":"event"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"MINT_WHITELIST","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"codexes","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"encumberance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"},{"internalType":"uint8","name":"slot_type","type":"uint8"},{"internalType":"address","name":"mint","type":"address"},{"internalType":"uint256","name":"token","type":"uint256"}],"name":"equip","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"common","type":"address"},{"internalType":"address","name":"common_armor_codex","type":"address"},{"internalType":"address","name":"common_weapon_codex","type":"address"},{"internalType":"address","name":"masterwork","type":"address"},{"internalType":"address","name":"masterwork_armor_codex","type":"address"},{"internalType":"address","name":"masterwork_weapon_codex","type":"address"}],"name":"set_mint_whitelist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint8","name":"","type":"uint8"}],"name":"slots","outputs":[{"internalType":"address","name":"mint","type":"address"},{"internalType":"uint256","name":"token","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"token","type":"uint256"},{"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"snapshot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint8","name":"","type":"uint8"}],"name":"snapshots","outputs":[{"internalType":"address","name":"mint","type":"address"},{"internalType":"uint256","name":"token","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"},{"internalType":"uint8","name":"slot_type","type":"uint8"}],"name":"unequip","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/
