// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexCommonGoods {
    function caltrops()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function candle()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function chain()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function class() external view returns (string memory);

    function crowbar()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function flint_and_steel()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function grappling_hook()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function hammer()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function index() external view returns (string memory);

    function ink()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function item_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function jug_clay()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lamp_common()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lantern_bullseye()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lantern_hooded()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lock_amazing()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lock_average()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lock_good()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function lock_very_simple()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function manacles()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function manacles_masterwork()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function oil()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function rope_hempen()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function rope_silk()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function spyglass()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function torch()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );

    function vial()
        external
        pure
        returns (
            uint256 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"caltrops","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"candle","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"chain","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"crowbar","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"flint_and_steel","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"grappling_hook","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"hammer","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ink","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"item_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"jug_clay","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lamp_common","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lantern_bullseye","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lantern_hooded","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lock_amazing","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lock_average","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lock_good","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lock_very_simple","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"manacles","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"manacles_masterwork","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"oil","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rope_hempen","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rope_silk","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spyglass","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"torch","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"vial","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"weight","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"}]
*/
