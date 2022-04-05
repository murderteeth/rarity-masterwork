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

    (,, uint ended, uint8 monster_count, uint8 monsters_defeated,,,,,) = ADVENTURE_2.adventures(adventure_token);
    require(ended > 0, "!adventure ended");
    require(monsters_defeated == monster_count, "!adventure won");

    uint reward = 0;
    uint8 turns = monster_count + 1;
    for(uint i = 0; i < turns; i++) {
      (bool summoner,,,,,,,,uint host) = ADVENTURE_2.turn_orders(adventure_token, i);
      if(!summoner) {
        reward += Monster.monster_by_id(uint8(host)).challenge_rating;
      }
    }

    _mint(_msgSender(), reward * 1e18);

    adventure_claims[adventure_token] = true;
  }

}