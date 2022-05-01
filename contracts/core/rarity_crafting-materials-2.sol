//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../library/Monster.sol";

interface IRarityAdventure2 {
  function getApproved(uint256 tokenId) external view returns (address);
  function ownerOf(uint256 tokenId) external view returns (address);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function adventures(uint) external view returns (bool dungeon_entered, bool combat_ended, bool search_check_rolled, bool search_check_succeeded, bool search_check_critical, uint8 monster_count, uint8 monsters_defeated, uint8 combat_round, uint64 started, uint64 ended, uint summoner);
  function turn_orders(uint, uint) external view returns (uint8 initiative_roll, int8 initiative_score, uint8 armor_class, int16 hit_points, address origin, uint token);
  function monster_spawn(uint) external view returns (uint8);
}

contract rarity_crafting_materials_2 is ERC20 {

  IRarityAdventure2 public ADVENTURE_2 = IRarityAdventure2(0x0000000000000000000000000000000000000009);

  constructor() ERC20("Rarity Crafting Materials (II)", "Craft (II)") {}

  mapping(uint => bool) public adventure_claims;

  function claim(uint adventure_token) public {
    require(isApprovedOrOwnerOfAdventure(adventure_token), "!approvedForAdventure");
    require(!adventure_claims[adventure_token], "claimed");

    (
      ,,,
      bool search_check_succeeded, 
      bool search_check_critical,
      uint8 monster_count, 
      uint8 monsters_defeated,
      ,,
      uint64 ended,
    ) = ADVENTURE_2.adventures(adventure_token);
    require(ended > 0, "!ended");
    require(monsters_defeated == monster_count, "!victory");

    uint reward = 0;
    uint8 turns = monster_count + 1;
    for(uint i = 0; i < turns; i++) {
      (,,,, address origin, uint token) = ADVENTURE_2.turn_orders(adventure_token, i);
      if(origin == address(ADVENTURE_2)) {
        uint8 monster_id = ADVENTURE_2.monster_spawn(token);
        reward += Monster.monster_by_id(monster_id).challenge_rating;
      }
    }

    if(search_check_succeeded) {
      if(search_check_critical) {
        reward = 6 * reward / 5;
      } else {
        reward = 23 * reward / 20;
      }
    }

    _mint(msg.sender, reward * 1e18 / 10);
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