//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";

interface IProjects {
  struct Project {
    uint crafter;
    uint8 baseType;
    uint8 itemType;
    uint check;
    uint xp;
    uint32 started;
    uint32 completed;
  }
  function projects(uint) external view returns (Project memory);
}

contract RarityMasterworkItem is ERC721Enumerable {
  uint public nextToken = 1;
  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IProjects projects = IProjects(0x000000000000000000000000000000000000dEaD);
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
    require(authorizeSummoner(project.crafter), "!authorizeSummoner");

    _safeMint(msg.sender, nextToken);
    items[nextToken] = Item(project.baseType, project.itemType, uint32(block.timestamp), project.crafter);
    claimed[projectToken] = true;
    emit Claimed(msg.sender, nextToken, projectToken);

    nextToken++;
  }

  function authorizeSummoner(uint summoner) internal view returns (bool) {
    address owner = rarity.ownerOf(summoner);
    return owner == msg.sender || rarity.getApproved(summoner) == msg.sender || rarity.isApprovedForAll(owner, msg.sender);
  }

}