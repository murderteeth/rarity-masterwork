//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Summoner.sol";

contract ForSummoners {
  modifier approvedForSummoner(uint256 summoner) {
    if (Summoner.isApprovedOrOwnerOfSummoner(summoner)) {
      _;
    } else {
      revert("!approvedForSummoner");
    }
  }
}