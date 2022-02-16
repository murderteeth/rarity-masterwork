// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RarityRandom {
    function dn(
        uint256 a,
        uint256 b,
        uint8 dieSides
    ) public view returns (uint8) {
        return uint8((_seed(a, b) % uint256(dieSides)) + 1);
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint256 a, uint256 b) internal view returns (uint256 rand) {
        rand = _random(
            string(abi.encodePacked(block.timestamp, a, b, msg.sender))
        );
    }
}
