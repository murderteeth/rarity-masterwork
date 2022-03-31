//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Crafting.sol";

contract ForItems {
  modifier approvedForItem(uint item, address itemContract) {
    if (
      (itemContract == address(0))
      || Crafting.isApprovedOrOwnerOfItem(item, itemContract)
    ) {
      _;
    } else {
      revert("!approvedForItem");
    }
  }
}