// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Base";
    string constant public class = "Random-2";

    function d100(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 100);
    }
    
    function d20(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 20);
    }
    
    function d12(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 12);
    }
    
    function d10(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 10);
    }
    
    function d8(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 8);
    }
    
    function d6(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 6);
    }
    
    function d4(uint a, uint b) external view returns (uint8) {
        return dn(a, b, 4);
    }

    function dn(uint a, uint b, uint8 die_sides) public view returns (uint8) {
        return uint8(_seed(a, b) % uint(die_sides) + 1);
    }

    function _random(string memory input) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(input)));
    }
    
    function _seed(uint a, uint b) internal view returns (uint rand) {
        rand = _random(
            string(
                abi.encodePacked(block.timestamp, a, b, msg.sender)
            )
        );
    }
}