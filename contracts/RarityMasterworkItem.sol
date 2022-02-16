//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";
import "./utils/RarityAuth.sol";

interface IProjects {
    struct Project {
        uint8 baseType;
        uint8 itemType;
        uint256 check;
        uint256 xp;
        uint32 started;
        uint32 completed;
    }

    function projects(uint256) external view returns (Project memory);

    function ownerOf(uint256) external view returns (uint256);
}

contract RarityMasterworkItem is ERC721Enumerable {
    uint256 public nextToken = 1;
    IProjects projects = IProjects(0x000000000000000000000000000000000000dEaD);
    event Claimed(address indexed owner, uint256 token, uint256 projectToken);

    constructor() ERC721("Rarity Masterwork Item", "RC(II)") {}

    struct Item {
        uint8 baseType;
        uint8 itemType;
        uint32 crafted;
        uint256 crafter;
    }

    mapping(uint256 => bool) public claimed;
    mapping(uint256 => Item) public items;

    function claim(uint256 projectToken) external {
        require(!claimed[projectToken], "claimed");
        IProjects.Project memory project = projects.projects(projectToken);
        require(project.completed > 0, "!completed");

        uint256 crafter = projects.ownerOf(projectToken);
        require(
            RarityAuth.isApprovedOrOwnerOfSummoner(crafter),
            "!authorizeSummoner"
        );

        _safeMint(msg.sender, nextToken);
        items[nextToken] = Item(
            project.baseType,
            project.itemType,
            uint32(block.timestamp),
            crafter
        );
        claimed[projectToken] = true;
        emit Claimed(msg.sender, nextToken, projectToken);

        nextToken++;
    }

    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (Item memory)
    {
        uint256 token = tokenOfOwnerByIndex(owner, index);
        return items[token];
    }
}
