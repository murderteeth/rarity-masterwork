//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../interfaces/core/IRarityCommonCrafting.sol";
import "../interfaces/core/IRarityCraftingMaterials2.sol";
import "../interfaces/core/IRarityGold.sol";
import "../library/Codex.sol";
import "../library/Crafting.sol";
import "../library/CraftingSkills.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Roll.sol";
import "../library/Skills.sol";
import "./rarity_crafting_masterwork_uri.sol";

contract rarity_masterwork is
    ERC721Enumerable,
    ERC721Holder,
    ReentrancyGuard,
    ForSummoners,
    ForItems
{
    uint256 public next_token = 1;

    uint8 constant MASTERWORK_COMPONENT_DC = 20;
    uint256 constant XP_PER_DAY = 250e18;
    uint256 public COMMON_ARTISANS_TOOLS_RENTAL = 5e18;
    uint256 public immutable APPRENTICE;

    IRarity constant RARITY =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRarityGold constant GOLD =
        IRarityGold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    IRarityCommonCrafting constant COMMON_CRAFTING =
        IRarityCommonCrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
    ICodexTools constant COMMON_TOOLS_CODEX =
        ICodexTools(0x0000000000000000000000000000000000000002);
    IRarityCraftingMaterials2 constant BONUS_MATS =
        IRarityCraftingMaterials2(0x0000000000000000000000000000000000000008);
    ICodexWeapon constant WEAPONS_CODEX =
        ICodexWeapon(0x0000000000000000000000000000000000000004);
    ICodexArmor constant ARMOR_CODEX =
        ICodexArmor(0x0000000000000000000000000000000000000005);
    ICodexTools constant TOOLS_CODEX =
        ICodexTools(0x0000000000000000000000000000000000000006);

    event Craft(
        address indexed owner,
        uint256 indexed token,
        uint256 crafter,
        uint256 bonus_mats,
        uint8 roll,
        int8 score,
        uint256 xp,
        uint256 m,
        uint256 n
    );
    event Crafted(
        address indexed owner,
        uint256 indexed token,
        uint256 crafter,
        uint8 base_type,
        uint8 item_type
    );

    constructor() ERC721("Rarity Crafting (II)", "RC(II)") {
        APPRENTICE = RARITY.next_summoner();
        RARITY.summon(2);
    }

    mapping(uint256 => MasterworkUri.Project) public projects;
    mapping(uint256 => MasterworkUri.Item) public items;

    function start(
        uint256 crafter,
        uint8 base_type,
        uint8 item_type,
        uint256 tools
    ) public approvedForSummoner(crafter) {
        require(
            tools == 0 ||
                Crafting.isApprovedOrOwnerOfItem(tools, address(this)),
            "!approvedForItem"
        );
        require(valid_item_type(base_type, item_type), "!valid_item_type");
        require(eligible(crafter), "!eligible");

        MasterworkUri.Project storage project = projects[next_token];
        project.base_type = base_type;
        project.item_type = item_type;
        project.started = uint64(block.timestamp);
        project.crafter = crafter;

        uint256 cost = raw_materials_cost(base_type, item_type);

        if (tools != 0) {
            MasterworkUri.Item memory toolsitem = items[tools];
            require(
                toolsitem.base_type == 4 && toolsitem.item_type == 2,
                "!Artisan's tools"
            );
            project.tools = tools;
            safeTransferFrom(msg.sender, address(this), tools);
        } else {
            cost += COMMON_ARTISANS_TOOLS_RENTAL;
        }

        require(
            GOLD.transferFrom(APPRENTICE, crafter, APPRENTICE, cost),
            "!gold"
        );

        _safeMint(msg.sender, next_token);
        next_token += 1;
    }

    function craft(uint256 token, uint256 bonus_mats)
        public
        approvedForItem(token, address(this))
    {
        MasterworkUri.Project storage project = projects[token];
        require(!project.done_crafting, "done_crafting");
        require(
            Rarity.isApprovedOrOwnerOfSummoner(project.crafter),
            "!approvedForSummoner"
        );

        (uint8 roll, int8 score) = Roll.craft(
            project.crafter,
            CraftingSkills.get_specialization(
                project.base_type,
                project.item_type
            )
        );

        score += craft_bonus(project, bonus_mats);
        if (bonus_mats > 0) BONUS_MATS.burn(msg.sender, bonus_mats);

        uint256 dc = uint256(get_dc(project));
        bool success = score >= int8(int256(dc));
        if (success) project.progress += uint256(score * int256(dc) * 1e18);
        uint256 cost_in_silver = item_cost_in_silver(
            project.base_type,
            project.item_type
        );

        if (!success) {
            RARITY.spend_xp(project.crafter, XP_PER_DAY);
            project.xp += XP_PER_DAY;
            emit Craft(
                msg.sender,
                token,
                project.crafter,
                bonus_mats,
                roll,
                score,
                XP_PER_DAY,
                project.progress,
                cost_in_silver
            );
            return;
        }

        if (project.progress < cost_in_silver) {
            RARITY.spend_xp(project.crafter, XP_PER_DAY);
            project.xp += XP_PER_DAY;
            emit Craft(
                msg.sender,
                token,
                project.crafter,
                bonus_mats,
                roll,
                score,
                XP_PER_DAY,
                project.progress,
                cost_in_silver
            );
        } else {
            uint256 prorate_xp = (XP_PER_DAY *
                (cost_in_silver -
                    (project.progress - uint256(score * int256(dc) * 1e18)))) /
                uint256(score * int256(dc) * 1e18);
            if (prorate_xp > 0) RARITY.spend_xp(project.crafter, prorate_xp);
            project.xp += prorate_xp;
            project.done_crafting = true;
            emit Craft(
                msg.sender,
                token,
                project.crafter,
                bonus_mats,
                roll,
                score,
                prorate_xp,
                project.progress,
                cost_in_silver
            );
        }
    }

    function complete(uint256 token)
        public
        approvedForItem(token, address(this))
    {
        MasterworkUri.Project storage project = projects[token];
        require(
            Rarity.isApprovedOrOwnerOfSummoner(project.crafter),
            "!approvedForSummoner"
        );
        require(project.done_crafting, "!done_crafting");
        require(!project.complete, "complete");

        MasterworkUri.Item storage item = items[token];
        item.base_type = project.base_type;
        item.item_type = project.item_type;
        item.crafted = uint64(block.timestamp);
        item.crafter = project.crafter;

        emit Crafted(
            msg.sender,
            token,
            project.crafter,
            item.base_type,
            item.item_type
        );

        project.complete = true;
        if (project.tools != 0) {
            this.safeTransferFrom(address(this), msg.sender, project.tools);
        }
    }

    function cancel(uint256 token)
        public
        approvedForItem(token, address(this))
    {
        MasterworkUri.Project storage project = projects[token];
        require(!project.done_crafting, "done_crafting");
        uint256 tools = project.tools;
        delete projects[token];
        _burn(token);
        if (tools != 0) {
            this.safeTransferFrom(address(this), msg.sender, tools);
        }
    }

    function valid_item_type(uint8 base_type, uint8 item_type)
        public
        pure
        returns (bool)
    {
        if (base_type == 2) {
            return (1 <= item_type && item_type <= 18);
        } else if (base_type == 3) {
            return (1 <= item_type && item_type <= 59);
        } else if (base_type == 4) {
            return (item_type == 2 ||
                item_type == 7 ||
                item_type == 9 ||
                item_type == 10);
        }
        return false;
    }

    function eligible(uint256 crafter) public view returns (bool) {
        return Skills.craft(crafter) > 0;
    }

    function max_bonus_mats(uint256 token) public view returns (uint256) {
        MasterworkUri.Project memory project = projects[token];
        return
            (project.tools == 0)
                ? 127 * 20e18
                : uint8(127 - skill_bonus(project.tools, 6)) * 20e18;
    }

    function craft_bonus(uint256 token, uint256 bonus_mats)
        public
        view
        returns (int8 result)
    {
        return craft_bonus(projects[token], bonus_mats);
    }

    function craft_bonus(
        MasterworkUri.Project memory project,
        uint256 bonus_mats
    ) internal view returns (int8 result) {
        result = (project.tools == 0) ? int8(0) : skill_bonus(project.tools, 6);
        if ((bonus_mats / 20e18) > uint8(127 - result)) {
            return int8(127);
        } else {
            result += int8(uint8(bonus_mats / 20e18));
        }
    }

    function skill_bonus(uint256 token, uint256 skill_id)
        internal
        view
        returns (int8 result)
    {
        MasterworkUri.Item memory item = items[token];
        if (item.base_type == 4) {
            return TOOLS_CODEX.get_skill_bonus(item.item_type, skill_id);
        }
    }

    function standard_component_dc(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint8 result)
    {
        if (base_type == 2) {
            result = 10 + ARMOR_CODEX.item_by_id(item_type).armor_bonus;
        } else if (base_type == 3) {
            result =
                12 +
                (WEAPONS_CODEX.item_by_id(item_type).proficiency - 1) *
                3;
        } else if (base_type == 4) {
            result = 15;
        }
    }

    function standard_component_cost_in_silver(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint256 result)
    {
        if (base_type == 2 || base_type == 3) {
            result = COMMON_CRAFTING.get_item_cost(base_type, item_type) * 10;
        } else if (base_type == 4) {
            result = COMMON_TOOLS_CODEX.item_by_id(item_type).cost * 10;
        }
    }

    function get_dc(uint256 token) public view returns (uint8) {
        MasterworkUri.Project memory project = projects[token];
        return get_dc(project);
    }

    function get_dc(MasterworkUri.Project memory project)
        public
        pure
        returns (uint8)
    {
        return
            (project.progress >=
                standard_component_cost_in_silver(
                    project.base_type,
                    project.item_type
                ))
                ? MASTERWORK_COMPONENT_DC
                : standard_component_dc(project.base_type, project.item_type);
    }

    function get_progress(uint256 token)
        public
        view
        returns (uint256, uint256)
    {
        MasterworkUri.Project memory project = projects[token];
        return progress(project);
    }

    function progress(MasterworkUri.Project memory project)
        public
        pure
        returns (uint256, uint256)
    {
        if (project.done_crafting) return (1, 1);
        return (
            project.progress,
            item_cost_in_silver(project.base_type, project.item_type)
        );
    }

    function get_craft_check_odds(
        uint256 token,
        uint256 summoner,
        uint256 bonus_mats
    ) public view returns (int8 average_score, uint8 dc) {
        MasterworkUri.Project memory project = projects[token];
        (average_score, dc) = craft_check_odds(project, summoner, bonus_mats);
    }

    function craft_check_odds(
        MasterworkUri.Project memory project,
        uint256 summoner,
        uint256 bonus_mats
    ) public view returns (int8 average_score, uint8 dc) {
        (uint8 roll, int8 score) = Roll.craft(
            summoner,
            CraftingSkills.get_specialization(
                project.base_type,
                project.item_type
            )
        );
        average_score =
            score -
            int8(roll) +
            10 +
            craft_bonus(project, bonus_mats);
        dc = get_dc(project);
    }

    function estimate_remaining_xp_cost(
        uint256 token,
        uint256 summoner,
        uint256 bonus_mats
    ) public view returns (uint256 xp) {
        MasterworkUri.Project memory project = projects[token];
        uint256 silver = item_cost_in_silver(
            project.base_type,
            project.item_type
        );
        (int8 average_score, ) = craft_check_odds(
            project,
            summoner,
            bonus_mats
        );
        uint256 average_score_uint = uint256(uint8(average_score));
        return (XP_PER_DAY * silver) / ((average_score_uint**2) * 1e18);
    }

    function item_cost_in_silver(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint256 cost)
    {
        return item_cost(base_type, item_type) * 10;
    }

    function item_cost(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint256 cost)
    {
        if (base_type == 2) {
            cost = ARMOR_CODEX.item_by_id(item_type).cost;
        } else if (base_type == 3) {
            cost = WEAPONS_CODEX.item_by_id(item_type).cost;
        } else if (base_type == 4) {
            cost = TOOLS_CODEX.item_by_id(item_type).cost;
        }
    }

    function project_cost(uint256 token) public view returns (uint256 result) {
        MasterworkUri.Project memory project = projects[token];
        result = raw_materials_cost(project.base_type, project.item_type);
        if (project.tools == 0) result += COMMON_ARTISANS_TOOLS_RENTAL;
    }

    function raw_materials_cost(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint256)
    {
        return item_cost(base_type, item_type) / 3;
    }

    function tokenURI(uint256 token)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        MasterworkUri.Project memory project = projects[token];
        if (project.complete) {
            uint256 base_type = items[token].base_type;
            if (base_type == 2) {
                return MasterworkUri.armor_uri(token, items[token]);
            } else if (base_type == 3) {
                return MasterworkUri.weapon_uri(token, items[token]);
            } else if (base_type == 4) {
                return MasterworkUri.tools_uri(token, items[token]);
            }
        } else {
            (uint256 m, uint256 n) = progress(project);
            return
                MasterworkUri.project_uri(token, project, items[token], m, n);
        }
    }
}
