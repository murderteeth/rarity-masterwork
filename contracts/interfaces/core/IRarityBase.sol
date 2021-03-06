// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityBase {
    function casting_time(uint256 id)
        external
        pure
        returns (string memory description);

    function classes(uint256 id)
        external
        pure
        returns (string memory description);

    function range(uint256 id)
        external
        pure
        returns (string memory description);

    function saving_throw_effect(uint256 id)
        external
        pure
        returns (string memory description);

    function saving_throw_type(uint256 id)
        external
        pure
        returns (string memory description);

    function school(uint256 id)
        external
        pure
        returns (string memory description);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"casting_time","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"classes","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"range","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"saving_throw_effect","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"saving_throw_type","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"school","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"}]
*/
