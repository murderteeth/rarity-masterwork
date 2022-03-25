//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICrafting {
  function getApproved(uint craft) external view returns(address);
  function ownerOf(uint craft) external view returns(address);
  function isApprovedForAll(address owner, address operator) external view returns(bool);
}

library Crafting {
  function isApprovedOrOwnerOfCraft(address contractAddress, uint256 craft) public view returns (bool) {
    ICrafting crafting = ICrafting(contractAddress);
    return crafting.getApproved(craft) == msg.sender
      || crafting.ownerOf(craft) == msg.sender
      || crafting.isApprovedForAll(crafting.ownerOf(craft), msg.sender);
  }
}