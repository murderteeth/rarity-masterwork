// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../library/Codex.sol";

contract codex {
  string constant public index = "Items";
  string constant public class = "Tools";
  uint8 constant public base_type = 4;

  function item_by_id(uint _id) public pure returns(ITools.Tools memory result) {
    if (_id == 2) {
      result = artisans_tools();
    }
  }

  function artisans_tools() public pure returns (ITools.Tools memory result) {
    result.id = 2;
    result.weight = 5;
    result.cost = 5e18;
    result.name = "Artisan's Tools";
    result.description = "These special tools include the items needed to pursue any craft. Without them, you have to use improvised tools (-2 penalty on Craft checks), if you can do the job at all.";
    result.skill_bonus[6] = 0;
  }
}