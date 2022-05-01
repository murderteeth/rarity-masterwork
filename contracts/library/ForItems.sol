//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Crafting.sol";

contract ForItems {
  modifier approvedForItem(uint item, address item_contract) {
    if (
      (item_contract == address(0))
      || Crafting.isApprovedOrOwnerOfItem(item, item_contract)
    ) {
      _;
    } else {
      revert("!approvedForItem");
    }
  }
}