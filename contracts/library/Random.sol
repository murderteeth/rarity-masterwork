//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/codex/IRarityCodexBaseRandom2.sol";

library Random {
  IRarityCodexBaseRandom2 public constant RANDOM 
    = IRarityCodexBaseRandom2(0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18);

  function dn(
    uint seed_a,
    uint seed_b,
    uint8 dice_sides
  ) public view returns (uint8) {
    return RANDOM.dn(seed_a, seed_b, dice_sides);
  }

  function dn(
    uint seed_a,
    uint seed_b,
    uint8 dice_count,
    uint8 dice_sides
  ) public view returns (uint8) {
    uint8 result = 0;
    for(uint i; i < dice_count; i++) {
      result += RANDOM.dn(seed_a + i, seed_b, dice_sides);
    }
    return result;
  }
}