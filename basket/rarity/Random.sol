// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/interfaces/ICodexRandom.sol";

library Random {
    ICodexRandom public constant CODEX_RANDOM =
        ICodexRandom(0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18);

    function dn(
        uint256 a,
        uint256 b,
        uint8 dieSides
    ) public view returns (uint8) {
        return CODEX_RANDOM.dn(a, b, dieSides);
    }
}
