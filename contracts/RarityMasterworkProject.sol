//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./extended/rERC721Enumerable.sol";
import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";

contract RarityMasterworkProject is rERC721Enumerable {
    string public constant name = "Rarity Masterwork Project";
    string public constant symbol = "RC(II) Project";
    uint256 constant MASTERWORK_COMPONENT_DC = 20;
    uint256 constant XP_PER_DAY = 250e18;
    uint256 public immutable APPRENTICE;
    uint256 public nextToken = 1;

    IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IAttributes attributes =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    ISkills skills = ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    IGold gold = IGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    ICrafting commonCrafting =
        ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
    codex_items_weapons masterworkWeaponsCodex =
        codex_items_weapons(0x000000000000000000000000000000000000dEaD);

    event Started(
        address indexed owner,
        uint256 tokenId,
        uint256 crafter,
        uint8 baseType,
        uint8 itemType,
        uint256 gold
    );
    event Craft(
        address indexed owner,
        uint256 tokenId,
        uint256 crafter,
        int256 check,
        uint256 mats,
        uint256 xp,
        uint256 m,
        uint256 n
    );
    event Crafted(
        address indexed owner,
        uint256 tokenId,
        uint256 crafter,
        uint8 baseType,
        uint8 itemType
    );

    constructor() ERC721(address(rarity)) {
        APPRENTICE = rarity.next_summoner();
        rarity.summon(2);
    }

    struct Project {
        uint8 baseType;
        uint8 itemType;
        uint256 check;
        uint256 xp;
        uint32 started;
        uint32 completed;
    }

    mapping(uint256 => Project) public projects;

    function start(
        uint256 crafter,
        uint8 baseType,
        uint8 itemType
    ) external {
        require(authorizeSummoner(crafter), "!authorizeSummoner");
        uint256 cost = getRawMaterialCost(baseType, itemType);
        require(
            gold.transferFrom(APPRENTICE, crafter, APPRENTICE, cost),
            "!gold"
        );

        _safeMint(crafter, nextToken);
        projects[nextToken] = Project(
            baseType,
            itemType,
            0,
            0,
            uint32(block.timestamp),
            0
        );
        emit Started(msg.sender, nextToken, crafter, baseType, itemType, cost);

        nextToken++;
    }

    function craft(uint256 token, uint256 mats) external {
        Project storage project = projects[token];
        require(
            project.started > 0 && project.completed == 0,
            "!project started"
        );
        uint256 crafter = ownerOf(token);

        // TODO: no progress on check fail
        // TODO: review check bonus progress
        // TODO: adjust DC for mat bonus
        (, int256 check) = commonCrafting.craft_skillcheck(
            crafter,
            MASTERWORK_COMPONENT_DC
        );
        project.check = project.check + uint256(check);

        (uint256 m, uint256 n) = progress(crafter);
        if (m < n) {
            rarity.spend_xp(crafter, XP_PER_DAY);
            project.xp = project.xp + XP_PER_DAY;
            emit Craft(
                msg.sender,
                token,
                crafter,
                check,
                mats,
                XP_PER_DAY,
                m,
                n
            );
        } else {
            uint256 xp = XP_PER_DAY - (XP_PER_DAY * (m - n)) / n;
            rarity.spend_xp(crafter, xp);
            project.xp = project.xp + xp;
            project.completed = uint32(block.timestamp);
            emit Craft(msg.sender, token, crafter, check, mats, xp, m, n);
            emit Crafted(
                msg.sender,
                token,
                crafter,
                project.baseType,
                project.itemType
            );
        }
    }

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
