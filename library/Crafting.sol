//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICrafting {
  function getApproved(uint craft) external view returns(address);
  function ownerOf(uint craft) external view returns(address);
  function isApprovedForAll(address owner, address operator) external view returns(bool);
  function safeTransferFrom(address from, address to, uint tokenId) external;
  function items(uint token) external view returns (uint8 base_type, uint8 item_type, uint32 crafted, uint256 crafter);
}

library Crafting {
  function isApprovedOrOwnerOfItem(address craftingAddress, uint craft) public view returns (bool) {
    ICrafting crafting = ICrafting(craftingAddress);
    return crafting.getApproved(craft) == msg.sender
      || crafting.ownerOf(craft) == msg.sender
      || crafting.isApprovedForAll(crafting.ownerOf(craft), msg.sender);
  }
}