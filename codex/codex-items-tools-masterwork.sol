// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract codex {
  string constant public index = "Items";
  string constant public class = "Masterwork Tools";
  uint8 constant public base_type = 4;

  function item_by_id(uint _id) public pure returns(
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    if (_id == 1) {
      return alchemists_lab();
    } else if(_id == 2) {
      return artisans_tools();
    } else if(_id == 3) {
      return climbers_kit();
    } else if(_id == 4) {
      return disguise_kit();
    } else if(_id == 5) {
      return healers_kit();
    } else if(_id == 6) {
      return magnifying_glass();
    } else if(_id == 7) {
      return musical_instrument();
    } else if(_id == 8) {
      return merchants_scale();
    } else if(_id == 9) {
      return thieves_tools();
    } else if(_id == 10) {
      return multitool();
    } else if(_id == 11) {
      return water_clock();
    }
  }

  function alchemists_lab() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 1;
    name = "Alchemist's lab";
    cost = 500e18;
    weight = 40;
    description = "An alchemist's lab always has the perfect tool for making alchemical items, so it provides a +2 circumstance bonus on Craft (alchemy) checks. It has no bearing on the costs related to the Craft (alchemy) skill. Without this lab, a character with the Craft (alchemy) skill is assumed to have enough tools to use the skill but not enough to get the +2 bonus that the lab provides.";
    skill_bonus[5] = 2;
  }

  function artisans_tools() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 2;
    name = "Masterwork Artisan's Tools";
    cost = 55e18;
    weight = 5;
    description = "These tools serve the same purpose as artisan's tools, but masterwork artisan's tools are the perfect tools for the job, so you get a +2 circumstance bonus on Craft checks made with them.";
    skill_bonus[5] = 2;
  }

  function climbers_kit() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 3;
    name = "Climber's Kit";
    cost = 80e18;
    weight = 5;
    description = "This is the perfect tool for climbing and gives you a +2 circumstance bonus on Climb checks.";
    skill_bonus[3] = 2;
  }

  function disguise_kit() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 4;
    name = "Disguise Kit";
    cost = 50e18;
    weight = 8;
    description = "The kit is the perfect tool for disguise and provides a +2 circumstance bonus on Disguise checks. A disguise kit is exhausted after ten uses.";
    skill_bonus[9] = 2;
  }

  function healers_kit() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 5;
    name = "Healer's Kit";
    cost = 50e18;
    weight = 1;
    description = "It is the perfect tool for healing and provides a +2 circumstance bonus on Heal checks. A healer's kit is exhausted after ten uses.";
    skill_bonus[14] = 2;
  }

  function magnifying_glass() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 6;
    name = "Magnifying Glass";
    cost = 100e18;
    weight = 0;
    description = "This simple lens allows a closer look at small objects. It is also useful as a substitute for flint and steel when starting fires. Lighting a fire with a magnifying glass requires light as bright as sunlight to focus, tinder to ignite, and at least a full-round action. A magnifying glass grants a +2 circumstance bonus on Appraise checks involving any item that is small or highly detailed.";
    skill_bonus[0] = 2;
  }

  function musical_instrument() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 7;
    name = "Masterwork Musical Instrument";
    cost = 100e18;
    weight = 3;
    description = "A masterwork instrument grants a +2 circumstance bonus on Perform checks involving its use.";
    skill_bonus[22] = 2;
  }

  function merchants_scale() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 8;
    name = "Merchant's Scale";
    cost = 2e18;
    weight = 1;
    description = "A scale grants a +2 circumstance bonus on Appraise checks involving items that are valued by weight, including anything made of precious metals.";
    skill_bonus[0] = 2;
  }

  function thieves_tools() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 9;
    name = "Masterwork Thieves Tools";
    cost = 100e18;
    weight = 2;
    description = "This kit contains extra tools and tools of better make, which grant a +2 circumstance bonus on Disable Device and Open Lock checks.";
    skill_bonus[9] = 2;
    skill_bonus[22] = 2;
  }

  function multitool() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 10;
    name = "Masterwork Multitool";
    cost = 50e18;
    weight = 1;
    description = "This well-made item is the perfect tool for the job. It grants a +2 circumstance bonus on a related skill check (if any). Bonuses provided by multiple masterwork items used toward the same skill check do not stack.";
    skill_bonus;
  }

  function water_clock() public pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    int8[36] memory skill_bonus
  ) {
    id = 11;
    name = "Water Clock";
    cost = 1000e18;
    weight = 200;
    description = "This large, bulky contrivance gives the time accurate to within half an hour per day since it was last set. It requires a source of water, and it must be kept still because it marks time by the regulated flow of droplets of water.";
    skill_bonus;
  }
}