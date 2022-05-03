//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
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
import "../library/StringUtil.sol";

contract rarity_masterwork is ERC721Enumerable, IERC721Receiver, IWeapon, IArmor, ITools, IEffects, ForSummoners, ForItems {
  uint public next_token = 1;

  uint8 constant MASTERWORK_COMPONENT_DC = 20;
  uint constant XP_PER_DAY = 250e18;
  uint public COMMON_ARTISANS_TOOLS_RENTAL = 5e18;
  uint public immutable APPRENTICE;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityGold constant GOLD = IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
  IRarityCommonCrafting constant COMMON_CRAFTING = IRarityCommonCrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  ICodexSkills SKILLS_CODEX = ICodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
  ICodexTools COMMON_TOOLS_CODEX = ICodexTools(0x0000000000000000000000000000000000000002);
  IRarityCraftingMaterials2 BONUS_MATS = IRarityCraftingMaterials2(0x0000000000000000000000000000000000000008);
  ICodexWeapon WEAPONS_CODEX = ICodexWeapon(0x0000000000000000000000000000000000000004);
  ICodexArmor ARMOR_CODEX = ICodexArmor(0x0000000000000000000000000000000000000005);
  ICodexTools TOOLS_CODEX = ICodexTools(0x0000000000000000000000000000000000000006);

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
    uint tools
  ) public 
    approvedForSummoner(coinmaster)
  {
    require(tools == 0 || Crafting.isApprovedOrOwnerOfItem(tools, address(this)), "!approvedForItem");
    require(valid_item_type(base_type, item_type), "!valid_item_type");

    Project storage project = projects[next_token];
    project.base_type = base_type;
    project.item_type = item_type;
    project.started = uint64(block.timestamp);

    uint cost = raw_materials_cost(base_type, item_type);

    if(tools != 0) {
      Item memory toolsitem = items[tools];
      require(toolsitem.base_type == 4 && toolsitem.item_type == 2, "!Artisan's tools");
      project.tools = tools;
      safeTransferFrom(msg.sender, address(this), tools);
      IERC721Enumerable(address(this))
      .approve(msg.sender, tools);
    } else {
      cost += COMMON_ARTISANS_TOOLS_RENTAL;
    }

    require(GOLD.transferFrom(APPRENTICE, coinmaster, APPRENTICE, cost), "!gold");

    _safeMint(msg.sender, next_token);
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
    if(bonus_mats > 0) BONUS_MATS.burn(msg.sender, bonus_mats);

    uint dc = uint(get_dc(project));
    bool success = score >= int8(int(dc));
    if(success) project.progress += uint(score * int(dc) * 1e18);
    uint cost_in_silver = item_cost_in_silver(project.base_type, project.item_type);

    if(!success) {
      RARITY.spend_xp(crafter, XP_PER_DAY);
      project.xp += XP_PER_DAY;
      emit Craft(msg.sender, token, crafter, bonus_mats, roll, score, XP_PER_DAY, project.progress, cost_in_silver);
      return;
    }

    if(project.progress < cost_in_silver) {
      RARITY.spend_xp(crafter, XP_PER_DAY);
      project.xp += XP_PER_DAY;
      emit Craft(msg.sender, token, crafter, bonus_mats, roll, score, XP_PER_DAY, project.progress, cost_in_silver);
    } else {
      uint prorate_xp = XP_PER_DAY * (cost_in_silver - (project.progress - uint(score * int(dc) * 1e18))) / uint(score * int(dc) * 1e18);
      if(prorate_xp > 0) RARITY.spend_xp(crafter, prorate_xp);
      project.xp += prorate_xp;
      project.done_crafting = true;
      emit Craft(msg.sender, token, crafter, bonus_mats, roll, score, prorate_xp, project.progress, cost_in_silver);
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

    emit Crafted(msg.sender, token, crafter, item.base_type, item.item_type);

    project.complete = true;
    if(project.tools != 0) {
      safeTransferFrom(address(this), msg.sender, project.tools);
    }
  }

  function cancel(uint token) public approvedForItem(token, address(this)) {
    Project storage project = projects[token];
    require(!project.done_crafting, "done_crafting");
    uint tools = project.tools;
    delete projects[token];
    _burn(token);
    if(tools != 0) {
      safeTransferFrom(address(this), msg.sender, tools);
    }
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

  function max_bonus_mats(uint token) public view returns (uint) {
    Project memory project = projects[token];
    return (project.tools == 0)
    ? 127 * 20e18
    : uint8(127 - this.skill_bonus(project.tools, 5)) * 20e18;
  }

  function craft_bonus(uint token, uint bonus_mats) public view returns (int8 result) {
    return craft_bonus(projects[token], bonus_mats);
  }

  function craft_bonus(Project memory project, uint bonus_mats) internal view returns (int8 result) {
    result = (project.tools == 0)
    ? int8(0)
    : this.skill_bonus(project.tools, 5);
    if((bonus_mats / 20e18) > uint8(127 - result)) {
      return int8(127);
    } else {
      result += int8(uint8(bonus_mats / 20e18));
    }
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

  function _transfer(address from, address to, uint token) internal override {
    Project memory project = projects[token];
    if(project.tools != 0 && ownerOf(project.tools) == address(this)) {
      IERC721Enumerable(address(this)).approve(to, project.tools);
    }
    super._transfer(from, to, token);
  }

  function tokenURI(uint token) public view virtual override returns (string memory) {
    Project memory project = projects[token];
    if(project.complete) return item_uri(token);
    else return project_uri(token, project);
  }

  function project_uri(uint token, Project memory project) public view returns (string memory) {
    uint y = 0;
    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'category ', base_type_name(project.base_type), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'item ', item_name(project.base_type, project.item_type), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'status ', status_string(project), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'tools ', tools_string(project), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'progress ', progress_string(project), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'xp ', StringUtil.toString(project.xp / 1e18), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'started ', StringUtil.toString(project.started), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'ended ', ended_string(token, project), '</text>'));
    svg = string(abi.encodePacked(svg, '</svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "project #', StringUtil.toString(token), '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function item_uri(uint token) public view returns (string memory result) {
    uint base_type = items[token].base_type;
    if (base_type == 2) {
      return armor_uri(token);
    } else if (base_type == 3) {
      return weapon_uri(token);
    } else if (base_type == 4) {
      return tools_uri(token);
    }
  }

  function armor_uri(uint token) public view returns (string memory) {
    uint y = 0;
    Item memory item = items[token];
    IArmor.Armor memory armor = ARMOR_CODEX.item_by_id(item.item_type);

    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'category ', base_type_name(item.base_type), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'name ', armor.name, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'cost ', StringUtil.toString(armor.cost/1e18), 'gp</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'weight ', StringUtil.toString(armor.weight), 'lb</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'proficiency ', ARMOR_CODEX.get_proficiency_by_id(armor.proficiency), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'armor bonus ', StringUtil.toString(armor.armor_bonus), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'max_dex ', StringUtil.toString(armor.max_dex_bonus), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'penalty ', StringUtil.toString(armor.penalty), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'spell failure ', StringUtil.toString(armor.spell_failure), '%</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'bonus</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="20" y="', StringUtil.toString(y), '" class="base">', '-1 Armor Check Penalty</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'description ', armor.description, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafter ', StringUtil.toString(item.crafter), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafted ', StringUtil.toString(item.crafted), '</text>'));
    svg = string(abi.encodePacked(svg, '</svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', StringUtil.toString(token), '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function weapon_uri(uint token) public view returns (string memory) {
    uint y = 0;
    Item memory item = items[token];
    IWeapon.Weapon memory weapon = WEAPONS_CODEX.item_by_id(item.item_type);

    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'category ', base_type_name(item.base_type), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'name ', weapon.name, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'cost ', StringUtil.toString(weapon.cost/1e18), 'gp</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'weight ', StringUtil.toString(weapon.weight), 'lb</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'proficiency ', WEAPONS_CODEX.get_proficiency_by_id(weapon.proficiency), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'encumbrance ', WEAPONS_CODEX.get_encumbrance_by_id(weapon.encumbrance), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'damage 1d', StringUtil.toString(weapon.damage), ', ', WEAPONS_CODEX.get_damage_type_by_id(weapon.damage_type) ,'</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', '(modifier) x critical (', StringUtil.toString(weapon.critical_modifier), ') x ', StringUtil.toString(weapon.critical), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'range ', StringUtil.toString(weapon.range_increment), 'ft</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'bonus</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="20" y="', StringUtil.toString(y), '" class="base">', '+1 Attack</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'description ', weapon.description, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafter ', StringUtil.toString(item.crafter), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafted ', StringUtil.toString(item.crafted), '</text>'));
    svg = string(abi.encodePacked(svg, '</svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', StringUtil.toString(token), '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function tools_uri(uint token) public view returns (string memory) {
    uint y = 0;
    Item memory item = items[token];
    ITools.Tools memory tools = TOOLS_CODEX.item_by_id(item.item_type);

    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'category ', base_type_name(item.base_type), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'name ', tools.name, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'cost ', StringUtil.toString(tools.cost/1e18), 'gp</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'weight ', StringUtil.toString(tools.weight), 'lb</text>'));

    y += 20; (string memory bonus_fragment, uint y_after_bonus) = tools_bonus_svg_fragment(tools, y);
    svg = string(abi.encodePacked(svg, bonus_fragment));

    y = y_after_bonus; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'description ', tools.description, '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafter ', StringUtil.toString(item.crafter), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'crafted ', StringUtil.toString(item.crafted), '</text>'));
    svg = string(abi.encodePacked(svg, '</svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "item #', StringUtil.toString(token), '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function base_type_name(uint8 base_type) public pure returns (string memory result) {
    if (base_type == 2) {
      result = "Armor";
    } else if (base_type == 3) {
      result = "Weapons";
    } else if (base_type == 4) {
      result = "Tools";
    }
  }

  function item_name(uint8 base_type, uint8 item_type) public view returns (string memory result) {
    if(base_type == 2) {
      result = get_armor(item_type).name;
    } else if(base_type == 3) {
      result = get_weapon(item_type).name;
    } else if(base_type == 4) {
      result = get_tools(item_type).name;
    }
  }

  function status_string(Project memory project) internal pure returns (string memory) {
    if(project.complete) return "Complete";
    if(project.done_crafting) return "Ready for completion";
    return "Crafting";
  }

  function tools_string(Project memory project) internal pure returns (string memory) {
    if(project.tools > 0) return "Masterwork Artisan's Tools";
    return "Common Artisan's Tools (Rental)";
  }

  function progress_string(Project memory project) internal view returns (string memory) {
    (uint m, uint n) = progress(project);
    return string(abi.encodePacked(StringUtil.toString(m * 100 / n), "%"));
  }

  function ended_string(uint token, Project memory project) internal view returns (string memory) {
    if(project.complete) {
      return StringUtil.toString(items[token].crafted);
    } else {
      return "--";
    }
  }

  function tools_bonus_svg_fragment(ITools.Tools memory tools, uint y) internal view returns (string memory result, uint new_y) {
    result = string(abi.encodePacked('<text x="10" y="', StringUtil.toString(y), '" class="base">bonus</text>'));
    y += 20;
    for(uint i = 0; i < 36; i++) {
      int8 bonus = tools.skill_bonus[i];
      string memory sign = "";
      if(bonus != 0) {
        if(bonus > 0) sign = "+";
        (, string memory name,,,,,,) = SKILLS_CODEX.skill_by_id(i + 1);
        result = string(abi.encodePacked(result, '<text x="20" y="', StringUtil.toString(y), '" class="base">', sign, StringUtil.toString(bonus), ' ', name, '</text>'));
        y += 20;
      }
    }
    new_y = y;
  }
}