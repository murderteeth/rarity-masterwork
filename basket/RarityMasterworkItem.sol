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
        uint256 tools;
        address toolsContract;
        uint256 check;
        uint256 xp;
        uint32 started;
        uint32 completed;
    }

    function projects(uint256) external view returns (Project memory);

    function ownerOf(uint256) external view returns (uint256);
}

interface IToolsCodex {
    struct effects_struct {
        int256[36] skill_bonus;
    }

    function item_by_id(uint256 _id)
        external
        pure
        returns (
            uint8 id,
            uint256 cost,
            uint256 weight,
            string memory name,
            string memory description,
            effects_struct memory effects
        );
}

interface IEffects {
    function skill_bonus(uint256 token, uint8 skill)
        external
        view
        returns (int256);
}

contract RarityMasterworkItem is ERC721Enumerable, IEffects {
    uint256 public nextToken = 1;
    IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IProjects projects = IProjects(0x000000000000000000000000000000000000dEaD);
    IToolsCodex toolsCodex =
        IToolsCodex(0x000000000000000000000000000000000000dEaD);
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
        require(authorizeSummoner(crafter), "!authorizeSummoner");

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

    // TODO: tokenURI

    function skill_bonus(uint256 token, uint8 skill)
        external
        view
        override
        returns (int256)
    {
        Item memory item = items[token];
        (, , , , , IToolsCodex.effects_struct memory effects) = toolsCodex
            .item_by_id(item.itemType);
        return effects.skill_bonus[skill];
    }

    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (Item memory)
    {
        uint256 token = tokenOfOwnerByIndex(owner, index);
        return items[token];
    }

    function isValid(uint256 _base_type, uint256 _item_type)
        public
        pure
        returns (bool)
    {
        if (_base_type == 1) {
            return (1 <= _item_type && _item_type <= 24);
        } else if (_base_type == 2) {
            return (1 <= _item_type && _item_type <= 18);
        } else if (_base_type == 3) {
            return (1 <= _item_type && _item_type <= 59);
        }
        return false;
    }

    function authorizeSummoner(uint256 summoner) internal view returns (bool) {
        address owner = rarity.ownerOf(summoner);
        return
            owner == msg.sender ||
            rarity.getApproved(summoner) == msg.sender ||
            rarity.isApprovedForAll(owner, msg.sender);
    }
}
