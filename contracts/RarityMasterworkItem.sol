//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";

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

interface IEffects {
  function skill_bonus(uint token, uint8 skill) external view returns (int);
}

contract RarityMasterworkItem is ERC721Enumerable, IEffects {
  uint public nextToken = 1;
  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IProjects projects = IProjects(0x000000000000000000000000000000000000dEaD);
  IToolsCodex toolsCodex = IToolsCodex(0x000000000000000000000000000000000000dEaD);
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

  function skill_bonus(uint token, uint8 skill) override external view returns (int) {
    Item memory item = items[token];
    (,,,,,IToolsCodex.effects_struct memory effects) = toolsCodex.item_by_id(item.itemType);
    return effects.skill_bonus[skill];
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