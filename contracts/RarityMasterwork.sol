//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IAttributes.sol";
import "./core/interfaces/ISkills.sol";
import "./core/interfaces/IGold.sol";
import "./core/interfaces/ICrafting.sol";

contract RarityMasterwork is ERC721Enumerable, IERC721Receiver {
    uint constant MASTERWORK_COMPONENT_DC = 20;
    uint constant XP_PER_DAY = 250e18;
    uint public nextToken;

    IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IAttributes attributes = IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    ISkills skills = ISkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    IGold gold = IGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    ICrafting commonCrafting = ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

    event Started(address indexed owner, uint crafter, uint commonItem, uint gold);
    event Craft(address indexed owner, uint crafter, int check, uint mats, uint xp, uint m, uint n);

    uint public immutable APPRENTICE;

    constructor() ERC721("Rarity Masterwork Crafting", "RC(II)") {
        APPRENTICE = rarity.next_summoner();
        rarity.summon(2);
    }

    struct Project {
        uint commonItem;
        uint16 check;
        bool complete;
        uint32 started;
        uint crafter;
    }

    struct Component {
        uint32 crafted;
        uint crafter;
    }

    mapping(uint => address) public owners;
    mapping(uint => Project) public projects;
    mapping(uint => Component) public components;

    function start(uint crafter, uint commonItem) external {
        require(authorizeSummoner(crafter), "!authorizeSummoner");
        require(authorizeCommonItem(commonItem), "!authorizeCommonItem");

        uint cost = rawMaterialCost(commonItem);
        require(gold.transferFrom(APPRENTICE, crafter, APPRENTICE, cost), "!gold");

        owners[commonItem] = msg.sender;
        commonCrafting.safeTransferFrom(msg.sender, address(this), commonItem);
        // The onERC721Received implementation below gets called back at this point by the Crafting I contract
        projects[nextToken] = Project(commonItem, 0, false, uint32(block.timestamp), crafter);
        _safeMint(msg.sender, nextToken);
        nextToken++;

        emit Started(msg.sender, crafter, commonItem, cost);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(commonCrafting), "!commonCrafting");
        require(operator == address(this), "!operator");
        require(from == owners[tokenId], "!previousOwner");
        return this.onERC721Received.selector;
    }

    function craft(uint tokenId, uint mats) external {
        Project memory project = projects[tokenId];

        // calculate dc
        // MASTERWORK_COMPONENT_DC - mat bonus

        (, int check) = commonCrafting.craft_skillcheck(project.crafter, MASTERWORK_COMPONENT_DC);
        project.check = project.check + uint16(uint(check));

        (uint m, uint n) = progress(tokenId);
        if(m < n) {
            rarity.spend_xp(project.crafter, XP_PER_DAY);
            emit Craft(msg.sender, project.crafter, check, mats, XP_PER_DAY, m, n);
        } else {
            uint xp = XP_PER_DAY - (XP_PER_DAY * (m - n)) / n;
            rarity.spend_xp(project.crafter, xp);
            project.complete = true;
            components[tokenId] = Component(uint32(block.timestamp), project.crafter);
            commonCrafting.safeTransferFrom(address(this), msg.sender, project.commonItem);
            emit Craft(msg.sender, project.crafter, check, mats, xp, m, n);
        }
    }

    function progress(uint tokenId) public view returns (uint, uint) {
        Project memory project = projects[tokenId];
        if(project.complete) {
            return(1, 1);
        }
        uint componentCostInSilver = componentCost(project.commonItem) * 10;
        return(project.check * MASTERWORK_COMPONENT_DC, componentCostInSilver);
    }

    function componentCost(uint commonItem) public view returns (uint) {
        (uint8 base_type,,,) = commonCrafting.items(commonItem);
        if(base_type == 1) {
            return(90);
        } else if(base_type == 2) {
            return(150);
        } else if(base_type == 3) {
            return(300);
        }
    }

    function rawMaterialCost(uint commonItem) public view returns (uint) {
        return(componentCost(commonItem) / 3);
    }

    function authorizeSummoner(uint summoner) internal view returns (bool) {
        address owner = rarity.ownerOf(summoner);
        return owner == msg.sender || rarity.getApproved(summoner) == msg.sender || rarity.isApprovedForAll(owner, msg.sender);
    }

    function authorizeCommonItem(uint commonItem) internal view returns (bool) {
        address owner = commonCrafting.ownerOf(commonItem);
        return owner == msg.sender || commonCrafting.getApproved(commonItem) == msg.sender || commonCrafting.isApprovedForAll(owner, msg.sender);
    }

}