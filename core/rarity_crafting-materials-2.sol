//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/core/IRarityAdventure2.sol";
import "../library/Monster.sol";

contract rarity_crafting_materials_2 is ERC20 {

  IRarityAdventure2 public ADVENTURE_2 = IRarityAdventure2(0x0000000000000000000000000000000000000000);

  constructor() ERC20("Rarity Crafting Materials (II)", "Craft (II)") {}

  mapping(uint => bool) public adventure_claims;

  function claim(uint adventure_token) public {
    require(ADVENTURE_2.isApprovedOrOwnerOfAdventure(adventure_token), "!approvedForAdventure");
    require(!adventure_claims[adventure_token], "claimed");

    (
      ,, 
      uint ended, 
      uint8 monster_count, 
      uint8 monsters_defeated,
      ,,,,
      bool search_check_succeeded, 
      bool search_check_critical
    ) = ADVENTURE_2.adventures(adventure_token);
    require(ended > 0, "!ended");
    require(monsters_defeated == monster_count, "!victory");

    uint reward = 0;
    uint8 turns = monster_count + 1;
    for(uint i = 0; i < turns; i++) {
      (bool summoner,,,,,uint token) = ADVENTURE_2.turn_orders(adventure_token, i);
      if(!summoner) {
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

    _mint(_msgSender(), reward * 1e18);
    adventure_claims[adventure_token] = true;
  }

  function burn(uint amount) public {
    _burn(_msgSender(), amount);
  }
}