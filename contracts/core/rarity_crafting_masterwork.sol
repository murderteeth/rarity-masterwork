//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../interfaces/core/IRarityCommonCrafting.sol";
import "../interfaces/core/IRarityCraftingMaterials2.sol";
import "../interfaces/core/IRarityGold.sol";
import "../library/Codex.sol";
import "../library/Crafting.sol";
import "../library/CraftingSkills.sol";
import "../library/Effects.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Roll.sol";
import "../library/Skills.sol";

contract rarity_masterwork is ERC721Enumerable, IERC721Receiver, IWeapon, IArmor, ITools, IEffects, ForSummoners, ForItems {
  uint public next_token = 1;

  uint8 constant MASTERWORK_COMPONENT_DC = 20;
  uint constant XP_PER_DAY = 250e18;
  uint public COMMON_ARTISANS_TOOLS_RENTAL = 5e18;
  uint public immutable APPRENTICE;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityGold constant GOLD = IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
  IRarityCommonCrafting constant COMMON_CRAFTING = IRarityCommonCrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  ICodexTools COMMON_TOOLS_CODEX = ICodexTools(0x0000000000000000000000000000000000000000);
  IRarityCraftingMaterials2 BONUS_MATS = IRarityCraftingMaterials2(0x0000000000000000000000000000000000000000);
  ICodexWeapon WEAPONS_CODEX = ICodexWeapon(0x0000000000000000000000000000000000000000);
  ICodexArmor ARMOR_CODEX = ICodexArmor(0x0000000000000000000000000000000000000000);
  ICodexTools TOOLS_CODEX = ICodexTools(0x0000000000000000000000000000000000000000);

  event Craft(address indexed owner, uint indexed token, uint crafter, uint bonus_mats, uint8 roll, int8 score, uint xp, uint m, uint n);
  event Crafted(address indexed owner, uint indexed token, uint crafter, uint8 base_type, uint8 item_type);

  constructor() ERC721("Rarity Crafting (II)", "RC(II)") {
    APPRENTICE = RARITY.next_summoner();
    RARITY.summon(2);
  }

  struct Project {
    bool done_crafting;
    bool complete;
    uint8 base_type;
    uint8 item_type;
    uint64 started;
    uint progress;
    uint tools;
    uint xp;
  }

  struct Item {
    uint8 base_type;
    uint8 item_type;
    uint64 crafted;
    uint crafter;
  }

  mapping(uint => Project) public projects;
  mapping(uint => Item) public items;

  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator; from; tokenId; data; // lint silencio!
    return this.onERC721Received.selector;
  }

  // IWeapon
  function get_weapon(uint8 item_type) override public view returns (IWeapon.Weapon memory) {
    return WEAPONS_CODEX.item_by_id(item_type);
  }

  // IArmor
  function get_armor(uint8 item_type) override public view returns (IArmor.Armor memory) {
    return ARMOR_CODEX.item_by_id(item_type);
  }

  // ITools
  function get_tools(uint8 item_type) override public view returns (ITools.Tools memory) {
    return TOOLS_CODEX.item_by_id(item_type);
  }

  // IEffects
  function armor_check_bonus(uint token) override external view returns (int8 result) {
    if(items[token].base_type == 2) result = 1;
  }

  function attack_bonus(uint token) override external view returns (int8 result) {
    if(items[token].base_type == 3) result = 1;
  }

  function skill_bonus(uint token, uint8 skill) override external view returns (int8 result) {
    Item memory item = items[token];
    if(item.base_type == 4) {
      ITools.Tools memory tools = TOOLS_CODEX.item_by_id(item.item_type);
      result = tools.skill_bonus[skill];
    }
  }

  function start(
    uint coinmaster,
    uint8 base_type,
    uint8 item_type,
    uint tools,
    address tools_contract
  ) public 
    approvedForSummoner(coinmaster)
    approvedForItem(tools, tools_contract) 
  {
    require(valid_item_type(base_type, item_type), "!valid_item_type");
    require(tools_contract == address(0) || tools_contract == address(this), "!whitelisted_tools");

    Project storage project = projects[next_token];
    project.base_type = base_type;
    project.item_type = item_type;
    project.started = uint64(block.timestamp);

    uint cost = raw_materials_cost(base_type, item_type);

    if(tools_contract != address(0)) {
      (uint8 tool_base_type, uint8 tool_type,,) = ICrafting(tools_contract).items(tools);
      require(tool_base_type == 4 && tool_type == 2, "!Artisan's tools");
      project.tools = tools;
      IERC721Enumerable(tools_contract)
      .safeTransferFrom(_msgSender(), address(this), tools);
      IERC721Enumerable(tools_contract)
      .approve(_msgSender(), tools);
    } else {
      cost += COMMON_ARTISANS_TOOLS_RENTAL;
    }

    require(GOLD.transferFrom(APPRENTICE, coinmaster, APPRENTICE, cost), "!gold");

    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function craft(
    uint token, 
    uint crafter,
    uint bonus_mats
  ) public 
    approvedForItem(token, address(this)) 
    approvedForSummoner(crafter) 
  {
    require(eligible(crafter), "!eligible");
    Project storage project = projects[token];
    require(!project.done_crafting, "done_crafting");

    (uint8 roll, int8 score) = Roll.craft(
      crafter, 
      CraftingSkills.get_specialization(project.base_type, project.item_type)
    );

    score += craft_bonus(project, bonus_mats);
    if(bonus_mats > 0) BONUS_MATS.burn(bonus_mats);

    uint dc = uint(get_dc(project));
    bool success = score >= int8(int(dc));
    if(success) project.progress += uint(score * int(dc) * 1e18);
    (uint m, uint n) = progress(project);

    if(!success) {
      RARITY.spend_xp(crafter, XP_PER_DAY);
      project.xp += XP_PER_DAY;
      emit Craft(_msgSender(), token, crafter, bonus_mats, roll, score, XP_PER_DAY, m, n);
      return;
    }

    if(m < n) {
      RARITY.spend_xp(crafter, XP_PER_DAY);
      project.xp += XP_PER_DAY;
      emit Craft(_msgSender(), token, crafter, bonus_mats, roll, score, XP_PER_DAY, m, n);
    } else {
      uint xp = XP_PER_DAY - (XP_PER_DAY * (m - n)) / n;
      RARITY.spend_xp(crafter, xp);
      project.xp += xp;
      project.done_crafting = true;
      emit Craft(_msgSender(), token, crafter, bonus_mats, roll, score, xp, m, n);
    }
  }

  function complete(
    uint token,
    uint crafter
  ) public 
    approvedForItem(token, address(this))
    approvedForSummoner(crafter)
  {
    Project storage project = projects[token];
    require(project.done_crafting, "!done_crafting");
    require(!project.complete, "complete");

    Item storage item = items[token];
    item.base_type = project.base_type;
    item.item_type = project.item_type;
    item.crafted = uint64(block.timestamp);
    item.crafter = crafter;

    emit Crafted(_msgSender(), token, crafter, item.base_type, item.item_type);

    if(project.tools != 0) {
      safeTransferFrom(address(this), _msgSender(), project.tools);
    }

    project.complete = true;
  }

  function cancel(uint token) public approvedForItem(token, address(this)) {
    Project storage project = projects[token];
    require(!project.done_crafting, "done_crafting");
    if(project.tools != 0) {
      safeTransferFrom(address(this), _msgSender(), project.tools);
    }
    delete projects[token];
    _burn(token);
  }

  function valid_item_type(uint8 base_type, uint8 item_type) public pure returns (bool) {
    if (base_type == 2) {
      return (1 <= item_type && item_type <= 18);
    } else if (base_type == 3) {
      return (1 <= item_type && item_type <= 59);
    } else if (base_type == 4) {
      return (1 <= item_type && item_type <= 11);
    }
    return false;
  }

  function eligible(uint crafter) public view returns (bool) {
    return Skills.craft(crafter) > 0;
  }

  function craft_bonus(uint token, uint bonus_mats) public view returns (int8 result) {
    return craft_bonus(projects[token], bonus_mats);
  }

  function craft_bonus(Project memory project, uint bonus_mats) internal view returns (int8 result) {
    result = (project.tools == 0)
    ? int8(0)
    : this.skill_bonus(project.tools, 5);
    result += int8(uint8(bonus_mats / 20e18));
  }

  function standard_component_dc(uint8 base_type, uint8 item_type) public view returns (uint8 result) {
    if(base_type == 2) {
      result = 10 + get_armor(item_type).armor_bonus;
    } else if(base_type == 3) {
      result = 12 + (get_weapon(item_type).proficiency - 1) * 3;
    } else if(base_type == 4) {
      result = 15;
    }
  }

  function standard_component_cost_in_silver(uint8 base_type, uint8 item_type) public view returns (uint result) {
    if(base_type == 2 || base_type == 3) {
      result = COMMON_CRAFTING.get_item_cost(base_type, item_type) * 10;
    } else if(base_type == 4) {
      result = COMMON_TOOLS_CODEX.item_by_id(item_type).cost * 10;
    }
  }

  function get_dc(uint token) public view returns (uint8) {
    Project memory project = projects[token];
    return get_dc(project);
  }

  function get_dc(Project memory project) public view returns (uint8) {
    return (project.progress >= standard_component_cost_in_silver(project.base_type, project.item_type))
    ? MASTERWORK_COMPONENT_DC
    : standard_component_dc(project.base_type, project.item_type);
  }

  function get_progress(uint token) public view returns (uint, uint) {
    Project memory project = projects[token];
    return progress(project);
  }

  function progress(Project memory project) public view returns (uint, uint) {
    if(project.done_crafting) return(1, 1);
    return(project.progress, item_cost_in_silver(project.base_type, project.item_type));
  }

  function get_craft_check_odds(uint token, uint summoner, uint bonus_mats) public view returns (int8 average_score, uint8 dc) {
    Project memory project = projects[token];
    (average_score, dc) = craft_check_odds(project, summoner, bonus_mats);
  }

  function craft_check_odds(Project memory project, uint summoner, uint bonus_mats) public view returns (int8 average_score, uint8 dc) {
    (uint8 roll, int8 score) = Roll.craft(
      summoner, 
      CraftingSkills.get_specialization(project.base_type, project.item_type)
    );
    average_score = score - int8(roll) + 10 + craft_bonus(project, bonus_mats);
    dc = get_dc(project);
  }

  function estimate_remaining_xp_cost(uint token, uint summoner, uint bonus_mats) public view returns (uint xp) {
    Project memory project = projects[token];
    uint silver = item_cost_in_silver(project.base_type, project.item_type);
    (int8 average_score,) = craft_check_odds(project, summoner, bonus_mats);
    uint average_score_uint = uint(uint8(average_score));
    return XP_PER_DAY * silver / ((average_score_uint**2)*1e18);
  }

  function item_cost_in_silver(uint8 base_type, uint8 item_type) public view returns (uint cost) {
    return item_cost(base_type, item_type) * 10;
  }

  function item_cost(uint8 base_type, uint8 item_type) public view returns (uint cost) {
    if(base_type == 2) {
      cost = ARMOR_CODEX.item_by_id(item_type).cost;
    } else if(base_type == 3) {
      cost = WEAPONS_CODEX.item_by_id(item_type).cost;
    } else if(base_type == 4) {
      cost = TOOLS_CODEX.item_by_id(item_type).cost;
    }
  }

  function project_cost(uint token) public view returns (uint result) {
    Project memory project = projects[token];
    result = raw_materials_cost(project.base_type, project.item_type);
    if(project.tools == 0) result += COMMON_ARTISANS_TOOLS_RENTAL;
  }

  function raw_materials_cost(uint8 base_type, uint8 item_type) public view returns (uint) {
    return item_cost(base_type, item_type) / 3;
  }

  // TODO: tokenURI
}