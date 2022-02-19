//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./extended/rERC721Enumerable.sol";
import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";

interface IEffects {
  function skill_bonus(uint token, uint8 skill) external view returns (int);
}

interface codex_base_random {
  function d20(uint _summoner) external view returns (uint);
}

contract RarityMasterworkProject is rERC721Enumerable {
  string public constant name = "Rarity Masterwork Project";
  string public constant symbol = "RC(II) Project";
  uint constant MASTERWORK_COMPONENT_DC = 20;
  uint constant XP_PER_DAY = 250e18;
  uint public immutable APPRENTICE;
  uint public nextToken = 1;

  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IAttributes attributes = IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
  ISkills skills = ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
  IGold gold = IGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
  codex_base_random random = codex_base_random(0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4);
  codex_items_weapons masterworkWeaponsCodex = codex_items_weapons(0x000000000000000000000000000000000000dEaD);

  event Started(address indexed owner, uint tokenId, uint crafter, uint8 baseType, uint8 itemType, uint tools, address toolsContract, uint gold);
  event Craft(address indexed owner, uint tokenId, uint crafter, uint mats, uint roll, int check, uint xp, uint m, uint n);
  event Crafted(address indexed owner, uint tokenId, uint crafter, uint8 baseType, uint8 itemType);

  constructor() ERC721(address(rarity)) {
    APPRENTICE = rarity.next_summoner();
    rarity.summon(2);
  }

  struct Project {
    uint8 baseType;
    uint8 itemType;
    uint tools;
    address toolsContract;
    uint check;
    uint xp;
    uint32 started;
    uint32 completed;
  }

  mapping(uint => Project) public projects;

  function start(uint crafter, uint8 baseType, uint8 itemType, uint tools, address toolsContract) external {
    require(authorizeSummoner(crafter), "!authorizeSummoner");
    //TODO: Validate base and type
    //TODO: Validate tools and toolsContract
    //TODO: Check tools whitelist
    //TODO: Authorize tools
    //TODO: Check that tools aren't already in use
    uint cost = getRawMaterialCost(baseType, itemType);
    require(gold.transferFrom(APPRENTICE, crafter, APPRENTICE, cost), "!gold");

    _safeMint(crafter, nextToken);
    projects[nextToken] = Project(baseType, itemType, tools, toolsContract, 0, 0, uint32(block.timestamp), 0);
    emit Started(msg.sender, nextToken, crafter, baseType, itemType, tools, toolsContract, cost);

    nextToken++;
  }

  function craftingBonus(uint token, uint mats) public view returns (uint crafter, bool eligible, int bonus) {
    crafter = ownerOf(token);
    uint craftSkill = uint(skills.get_skills(crafter)[5]);
    if(craftSkill == 0) return (crafter, false, 0);
    int result = int(craftSkill);

    (,,,uint intelligence,,) = attributes.ability_scores(crafter);
    if(intelligence < 10) {
      result = result - 1;
    } else {
      result = result + (int(intelligence) - 10) / 2;
    }

    Project memory project = projects[token];
    if(project.tools == 0) {
      result = result - 2;
    } else {
      result = result + IEffects(project.toolsContract).skill_bonus(project.tools, 5);
    }

    // TODO: mats bonus
    mats; //silence!

    return (crafter, true, result);
  }

  function craft_skillcheck(uint token, uint mats, uint dc) public view returns (uint roll, int check, bool success) {
    (uint crafter, bool eligible, int bonus) = craftingBonus(token, mats);
    if(!eligible) return (0, 0, false);
    check = bonus;
    roll = random.d20(crafter);
    check += int(roll);
    return (roll, check, check >= int(dc));
  }

  function craft(uint token, uint mats) external {
    Project storage project = projects[token];
    require(project.started > 0 && project.completed == 0, "!project started");
    uint crafter = ownerOf(token);

    // TODO: burn mats
    // TODO: review check progress rules
    (uint roll, int check, bool success) = craft_skillcheck(token, mats, MASTERWORK_COMPONENT_DC);
    if(success) project.check = project.check + uint(check);
    (uint m, uint n) = progress(token);

    if(!success) {
      emit Craft(msg.sender, token, crafter, mats, roll, check, XP_PER_DAY, m, n);
      return;
    }

    if(m < n) {
      rarity.spend_xp(crafter, XP_PER_DAY);
      project.xp = project.xp + XP_PER_DAY;
      emit Craft(msg.sender, token, crafter, mats, roll, check, XP_PER_DAY, m, n);
    } else {
      uint xp = XP_PER_DAY - (XP_PER_DAY * (m - n)) / n;
      rarity.spend_xp(crafter, xp);
      project.xp = project.xp + xp;
      project.completed = uint32(block.timestamp);
      emit Craft(msg.sender, token, crafter, mats, roll, check, xp, m, n);
      emit Crafted(msg.sender, token, crafter, project.baseType, project.itemType);
    }
  }

  // TODO: tokenURI

    function progress(uint256 token) public view returns (uint256, uint256) {
        Project memory project = projects[token];
        if (project.completed > 0) {
            return (1, 1);
        }
        uint256 costInSilver = getItemCost(project.baseType, project.itemType) *
            10;
        return (project.check * MASTERWORK_COMPONENT_DC * 1e18, costInSilver);
    }

    function getRawMaterialCost(uint8 baseType, uint8 itemType)
        public
        view
        returns (uint256)
    {
        return (getItemCost(baseType, itemType) / 3);
    }

    function getItemCost(uint8 baseType, uint8 itemType)
        public
        view
        returns (uint256 cost)
    {
        if (baseType == 1) {
            return (0);
        } else if (baseType == 2) {
            return (0);
        } else if (baseType == 3) {
            return masterworkWeaponsCodex.item_by_id(itemType).cost;
        }
    }

    function authorizeSummoner(uint256 summoner) internal view returns (bool) {
        address owner = rarity.ownerOf(summoner);
        return
            owner == msg.sender ||
            rarity.getApproved(summoner) == msg.sender ||
            rarity.isApprovedForAll(owner, msg.sender);
    }
}
