//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../library/Monster.sol";

interface IRarityAdventure2 {
  function getApproved(uint256 tokenId) external view returns (address);
  function ownerOf(uint256 tokenId) external view returns (address);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function is_ended(uint) external view returns (bool);
  function is_victory(uint) external view returns (bool);
  function count_loot(uint) external view returns (uint);
}

contract rarity_crafting_materials_2 is ERC20 {

  IRarityAdventure2 public ADVENTURE_2 = IRarityAdventure2(0x0000000000000000000000000000000000000009);

  constructor() ERC20("Rarity Crafting Materials (II)", "Craft (II)") {}

  mapping(uint => bool) public adventure_claims;

  function claim(uint adventure_token) public {
    require(isApprovedOrOwnerOfAdventure(adventure_token), "!approvedForAdventure");
    require(!adventure_claims[adventure_token], "claimed");
    require(ADVENTURE_2.is_ended(adventure_token), "!ended");
    require(ADVENTURE_2.is_victory(adventure_token), "!victory");
    _mint(msg.sender, ADVENTURE_2.count_loot(adventure_token));
    adventure_claims[adventure_token] = true;
  }

  function burn(address account, uint amount) public {
    _burn(account, amount);
  }

  function isApprovedOrOwnerOfAdventure(uint token) public view returns (bool) {
    if(ADVENTURE_2.getApproved(token) == msg.sender) return true;
    address owner = ADVENTURE_2.ownerOf(token);
    return owner == msg.sender || ADVENTURE_2.isApprovedForAll(owner, msg.sender);
  }
}