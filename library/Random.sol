//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexBaseRandom2.sol";

library Random {
  IRarityCodexBaseRandom2 public constant RANDOM 
    = IRarityCodexBaseRandom2(0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18);

  function dn(
    uint256 a,
    uint256 b,
    uint8 dieSides
  ) public view returns (uint8) {
    return RANDOM.dn(a, b, dieSides);
  }
}