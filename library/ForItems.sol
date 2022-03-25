//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Crafting.sol";

contract ForItems {
  modifier approvedForItem(address craftingAddress, uint craft) {
    if (
      (craftingAddress == address(0))
      || Crafting.isApprovedOrOwnerOfItem(craftingAddress, craft)
    ) {
      _;
    } else {
      revert("!approvedForItem");
    }
  }
}