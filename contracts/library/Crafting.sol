//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICrafting {
  function approve(address to, uint craft) external;
  function setApprovalForAll(address operator, bool approved) external;
  function getApproved(uint craft) external view returns(address);
  function ownerOf(uint craft) external view returns(address);
  function isApprovedForAll(address owner, address operator) external view returns(bool);
  function safeTransferFrom(address from, address to, uint tokenId) external;
  function items(uint token) external view returns (uint8 base_type, uint8 item_type, uint32 crafted, uint256 crafter);
}

library Crafting {
  function isApprovedOrOwnerOfItem(uint item, address item_contract) public view returns (bool) {
    ICrafting crafting = ICrafting(item_contract);
    if(crafting.getApproved(item) == msg.sender) return true;
    address owner = crafting.ownerOf(item);
    return owner == msg.sender || crafting.isApprovedForAll(owner, msg.sender);
  }
}