//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";

interface IProjects {
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
  function projects(uint) external view returns (Project memory);
  function ownerOf(uint) external view returns (uint);
}

interface IToolsCodex {
  struct effects_struct {
    int[36] skill_bonus;
  }

  function item_by_id(uint _id) external pure returns(
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    effects_struct memory effects
  );
}

interface IWeaponsCodex {
  struct effects_struct {
    int[8] roll_bonus;
  }

  function item_by_id(uint256 _id) external pure returns (
    codex_items_weapons.weapon memory _weapon,
    effects_struct memory effects
  );
}

interface IEffects {
  function skill_bonus(uint token, uint8 skill) external view returns (int);
  function roll_bonus(uint token, uint8 roll_type) external view returns (int);
}

contract RarityMasterworkItem is ERC721Enumerable, IEffects {
  uint public nextToken = 1;
  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IProjects projects = IProjects(0x000000000000000000000000000000000000dEaD);
  IToolsCodex toolsCodex = IToolsCodex(0x000000000000000000000000000000000000dEaD);
  IWeaponsCodex weaponsCodex = IWeaponsCodex(0x000000000000000000000000000000000000dEaD);
  event Claimed(address indexed owner, uint token, uint projectToken);

  constructor() ERC721("Rarity Masterwork Item", "RC(II)") {}

  struct Item {
    uint8 baseType;
    uint8 itemType;
    uint32 crafted;
    uint crafter;
  }

  mapping(uint => bool) public claimed;
  mapping(uint => Item) public items;

  function claim(uint projectToken) external {
    require(!claimed[projectToken], "claimed");
    IProjects.Project memory project = projects.projects(projectToken);
    require(project.completed > 0, "!completed");

    uint crafter = projects.ownerOf(projectToken);
    require(authorizeSummoner(crafter), "!authorizeSummoner");

    _safeMint(msg.sender, nextToken);
    items[nextToken] = Item(project.baseType, project.itemType, uint32(block.timestamp), crafter);
    claimed[projectToken] = true;
    emit Claimed(msg.sender, nextToken, projectToken);

    nextToken++;
  }

  // TODO: tokenURI

  function skill_bonus(uint token, uint8 skill) override external view returns (int bonus) {
    Item memory item = items[token];
    if(item.baseType == 4) {
      (,,,,,IToolsCodex.effects_struct memory effects) = toolsCodex.item_by_id(item.itemType);
      bonus = effects.skill_bonus[skill];
    }
  }

  function roll_bonus(uint token, uint8 roll_type) override external view returns (int bonus) {
    Item memory item = items[token];
    if(item.baseType == 3) {
      (,IWeaponsCodex.effects_struct memory effects) = weaponsCodex.item_by_id(item.itemType);
      bonus = effects.roll_bonus[roll_type];
    }
  }

  function itemOfOwnerByIndex(address owner, uint index) external view returns (Item memory) {
    uint token = tokenOfOwnerByIndex(owner, index);
    return items[token];
  }

  function authorizeSummoner(uint summoner) internal view returns (bool) {
    address owner = rarity.ownerOf(summoner);
    return owner == msg.sender || rarity.getApproved(summoner) == msg.sender || rarity.isApprovedForAll(owner, msg.sender);
  }

}