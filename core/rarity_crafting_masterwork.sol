//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/codex/IRarityCodexMasterworkArmor.sol";
import "../interfaces/codex/IRarityCodexMasterworkTools.sol";
import "../interfaces/codex/IRarityCodexMasterworkWeapons.sol";
import "../interfaces/core/IRarity.sol";
import "../interfaces/core/IRarityCraftingMaterials2.sol";
import "../interfaces/core/IRarityGold.sol";
import "../library/Crafting.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Roll.sol";
import "../library/Skills.sol";

interface ISkillBonus {
  function skill_bonus(uint token, uint8 skill) external view returns (int8);
}

contract rarity_masterwork is ERC721Enumerable, IERC721Receiver, ISkillBonus, ForSummoners, ForItems {
  uint public next_token = 1;
  address public TOOLS_WHITELIST_1 = address(this);
  address public TOOLS_WHITELIST_2 = 0x0000000000000000000000000000000000000000;

  int8 constant MASTERWORK_COMPONENT_DC = 20;
  uint constant XP_PER_DAY = 250e18;
  uint public immutable APPRENTICE;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityGold constant GOLD = IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
  IRarityCraftingMaterials2 BONUS_MATS = IRarityCraftingMaterials2(0x0000000000000000000000000000000000000000);
  IRarityCodexMasterworkArmor ARMOR_CODEX = IRarityCodexMasterworkArmor(0x0000000000000000000000000000000000000000);
  IRarityCodexMasterworkTools TOOLS_CODEX = IRarityCodexMasterworkTools(0x0000000000000000000000000000000000000000);
  IRarityCodexMasterworkWeapons WEAPONS_CODEX = IRarityCodexMasterworkWeapons(0x0000000000000000000000000000000000000000);

  event Craft(address indexed owner, uint token, uint crafter, uint bonus_mats, uint8 roll, int8 score, uint xp, uint m, uint n);
  event Crafted(address indexed owner, uint token, uint crafter, uint8 base_type, uint8 item_type);

  constructor() ERC721("Rarity Crafting (II)", "RC(II)") {
    APPRENTICE = RARITY.next_summoner();
    RARITY.summon(2);
  }

  struct Project {
    bool done_crafting;
    bool complete;
    uint8 base_type;
    uint8 item_type;
    uint32 progress;
    uint64 started;
    address tools_contract;
    uint tools;
    uint raw_materials;
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

  function skill_bonus(uint token, uint8 skill) override external view returns (int8 result) {
    Item memory item = items[token];
    if(item.base_type == 4) {
      (,,,,, int8[36] memory bonus) = TOOLS_CODEX.item_by_id(item.item_type);
      return bonus[skill];
    }
  }

  function start(
    uint8 base_type,
    uint8 item_type,
    uint tools,
    address tools_contract
  ) public 
    approvedForItem(tools, tools_contract) 
  {
    require(valid_item_type(base_type, item_type), "!valid_item_type");
    require(tools_contract == address(0) || whitelisted_tools(tools_contract), "!whitelisted_tools");

    Project storage project = projects[next_token];
    project.base_type = base_type;
    project.item_type = item_type;
    project.started = uint64(block.timestamp);

    if(tools_contract != address(0)) {
      (uint8 tool_base_type, uint8 tool_type,,) = ICrafting(tools_contract).items(tools);
      require(tool_base_type == 4 && tool_type == 2, "!Artisan's tools");
      project.tools = tools;
      project.tools_contract = tools_contract;
      IERC721Enumerable(tools_contract)
      .safeTransferFrom(_msgSender(), address(this), tools);
    }

    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function buy_raw_materials(
    uint token, 
    uint coinmaster
  ) public 
    approvedForItem(token, address(this)) 
  {
    Project storage project = projects[token];
    uint cost = raw_materials_cost(project.base_type, project.item_type);
    require(GOLD.transferFrom(APPRENTICE, coinmaster, APPRENTICE, cost), "!gold");
    project.raw_materials = cost;
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
    require(project.raw_materials == raw_materials_cost(project.base_type, project.item_type), "!raw_materials");
    require(!project.done_crafting, "done_crafting");

    (uint8 roll, int8 score) = Roll.craft(crafter);
    score += craft_bonus(token, bonus_mats);
    if(bonus_mats > 0) BONUS_MATS.burn(bonus_mats);

    bool success = score >= MASTERWORK_COMPONENT_DC;
    if(success) project.progress += uint32(int32(score));
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

    if(project.tools_contract != address(0)) {
      IERC721Enumerable(project.tools_contract)
      .safeTransferFrom(address(this), _msgSender(), project.tools);
    }

    project.complete = true;
  }

  function cancel(uint token) public approvedForItem(token, address(this)) {
    Project storage project = projects[token];
    require(!project.done_crafting, "done_crafting");
    if(project.tools_contract != address(0)) {
      IERC721Enumerable(project.tools_contract)
      .safeTransferFrom(address(this), _msgSender(), project.tools);
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

  function whitelisted_tools(address tools_contract) public view returns (bool) {
    return tools_contract == address(TOOLS_WHITELIST_1) 
    || tools_contract == address(TOOLS_WHITELIST_2);
  }

  function eligible(uint crafter) public view returns (bool) {
    return Skills.craft(crafter) > 0;
  }

  function craft_bonus(uint token, uint bonus_mats) public view returns (int8 result) {
    return craft_bonus(projects[token], bonus_mats);
  }

  function craft_bonus(Project memory project, uint bonus_mats) internal view returns (int8 result) {
    result = project.tools_contract == address(0)
    ? -2
    : ISkillBonus(project.tools_contract).skill_bonus(project.tools, 5);
    result += int8(uint8(bonus_mats / 200e18));
  }

  function get_progress(uint token) public view returns (uint, uint) {
    Project memory project = projects[token];
    return progress(project);
  }

  function progress(Project memory project) public view returns (uint, uint) {
    if(project.done_crafting) return(1, 1);
    uint cost_in_silver = item_cost(project.base_type, project.item_type) * 10;
    return(uint(project.progress) * uint(uint8(MASTERWORK_COMPONENT_DC)) * 1e18, cost_in_silver);
  }

  function item_cost(uint8 base_type, uint8 item_type) public view returns (uint cost) {
    if(base_type == 2) {
      cost = ARMOR_CODEX.item_by_id(item_type).cost;
    } else if(base_type == 3) {
      cost = WEAPONS_CODEX.item_by_id(item_type).cost;
    } else if(base_type == 4) {
      (,cost,,,,) = TOOLS_CODEX.item_by_id(item_type);
    }
  }

  function raw_materials_cost(uint8 base_type, uint8 item_type) public view returns (uint) {
    return item_cost(base_type, item_type) / 3;
  }

  // TODO: tokenURI
}