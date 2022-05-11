// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string public constant index = "Base";
    string public constant class = "Random";

    function d100(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 100);
    }

    function d20(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 20);
    }

    function d12(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 12);
    }

    function d10(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 10);
    }

    function d8(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 8);
    }

    function d6(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 6);
    }

    function d4(uint256 _summoner) external view returns (uint256) {
        return dn(_summoner, 4);
    }

    function dn(uint256 _summoner, uint256 _number)
        public
        view
        returns (uint256)
    {
        return _seed(_summoner) % _number;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint256 _summoner) internal view returns (uint256 rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _summoner,
                    msg.sender
                )
            )
        );
    }
}
