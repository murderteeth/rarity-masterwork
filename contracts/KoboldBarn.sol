//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/ICodexItemsArmor.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";
import "./core/interfaces/ICrafting.sol";

import "./utils/RaritySkillCheck.sol";
import "./utils/Rarity.sol";

contract KoboldBarn is ERC721Enumerable {
    uint256 public nextToken = 1;

    ICrafting private constant COMMON_CRAFTING =
        ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

    // address private constant COMMON_ARMOR_ADDRESS =
    // 0xf5114A952Aca3e9055a52a87938efefc8BB7878C;
    // address private constant COMMON_WEAPONS_ADDRESS =
    // 0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8;

    // codex_items_weapons private constant COMMON_WEAPONS =
    // codex_items_weapons(COMMON_WEAPONS_ADDRESS);
    // codex_items_armor private constant COMMON_ARMOR =
    // codex_items_armor(COMMON_ARMOR_ADDRESS);

    // codex_items_weapons private constant MASTERWORK_WEAPONS =
    // codex_items_weapons(COMMON_WEAPONS_ADDRESS);
    // codex_items_armor private constant MASTERWORK_ARMOR =
    // codex_items_armor(COMMON_ARMOR_ADDRESS);

    // Helper constants
    uint256 private constant DAY = 1 days;

    constructor() ERC721("Rarity Kobold", "RK") {}

    struct Kobold {
        uint8 health;
        uint256 summonerId;
        uint8 summonerHealth;
        uint256 armorId;
        uint256 weaponId;
        uint256 enteredAt;
        bool isMasterworkWeapon;
        bool isMasterworkArmor;
    }

    mapping(address => bool) private weapons;
    mapping(address => bool) private armor;

    mapping(uint256 => uint256) public latestFight; // summonerId => koboldId
    mapping(uint256 => Kobold) public kobolds;
    mapping(uint256 => uint256) public lastAttack;

    function enter(
        uint256 summonerId,
        uint256 weaponId,
        bool isMasterworkWeapon,
        uint256 armorId,
        bool isMasterworkArmor
    ) external approvedForSummoner(summonerId) canAttackYet(summonerId) {
        if (isMasterworkWeapon) {
            require(false, "!masterwork weapon");
        } else {
            (uint8 weaponBase, uint8 weaponType, , ) = COMMON_CRAFTING.items(
                weaponId
            );
            require(weaponBase == 3, "!armor");
            require(COMMON_CRAFTING.isValid(weaponBase, weaponType), "!armor");
            require(
                _msgSender() == COMMON_CRAFTING.ownerOf(weaponId),
                "!common weapon"
            );
        }
        if (isMasterworkArmor) {
            require(false, "!masterwork armor");
        } else {
            (uint8 armorBase, uint8 armorType, , ) = COMMON_CRAFTING.items(
                armorId
            );
            require(armorBase == 2, "!armor");
            require(
                COMMON_CRAFTING.isValid(armorBase, armorType),
                "!valid armor"
            );
            require(
                _msgSender() == COMMON_CRAFTING.ownerOf(armorId),
                "!common armor"
            );
        }
        Kobold memory kobold = _startFight(
            summonerId,
            weaponId,
            isMasterworkWeapon,
            armorId,
            isMasterworkArmor
        );
        _fight(kobold, summonerId);
    }

    // Attack to start or continue a fight
    function attack(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
        canAttackYet(summonerId)
    {
        // Get the summoner's latest kobold
        uint256 koboldId = latestFight[summonerId];
        require(!isEnded(koboldId), "!ended");

        Kobold memory latestKobold = kobolds[koboldId];

        // TODO here's a weird scenario - what if this summoner is attacking this
        // kobold, but the kobold battle transferred to another wallet?
        require(_isApprovedOrOwner(_msgSender(), koboldId), "!kobold");

        _fight(latestKobold, summonerId);
    }

    function summonerOf(uint256 koboldId) public view returns (uint256) {
        return kobolds[koboldId].summonerId;
    }

    function isWon(uint256 koboldId) public view returns (bool) {
        return kobolds[koboldId].health == 0;
    }

    function isEnded(uint256 koboldId) public view returns (bool) {
        Kobold memory kobold = kobolds[koboldId];
        return kobold.health == 0 || kobold.summonerHealth == 0;
    }

    function _fight(Kobold memory kobold, uint256 summonerId) internal {
        lastAttack[summonerId] = block.timestamp;
        // TODO determine winner
        // TODO decrement loser health

        // If masterwork weapon, +1 attack bonus
        // if masterwork armor, +1 defense bonus
    }

    function _startFight(
        uint256 summonerId,
        uint256 weaponId,
        bool isMasterworkWeapon,
        uint256 armorId,
        bool isMasterworkArmor
    ) internal returns (Kobold memory) {
        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);

        // Sneak attack means the kobold could start with 9 health
        latestFight[summonerId] = newTokenId;
        kobolds[newTokenId].health = _koboldStartingHealth(summonerId);
        kobolds[newTokenId].summonerId = summonerId;
        kobolds[newTokenId].weaponId = weaponId;
        kobolds[newTokenId].isMasterworkWeapon = isMasterworkWeapon;
        kobolds[newTokenId].armorId = armorId;
        kobolds[newTokenId].isMasterworkArmor = isMasterworkArmor;

        kobolds[newTokenId].summonerHealth = Rarity.health(summonerId);

        lastAttack[summonerId] = block.timestamp;

        nextToken += 1;

        return kobolds[newTokenId];
    }

    function _koboldStartingHealth(uint256 summonerId)
        internal
        view
        returns (uint8)
    {
        if (RaritySkillCheck.senseMotive(summonerId) >= 15) {
            // Sneak attack!
            return 9;
        } else {
            return 10;
        }
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (Rarity._isApprovedOrOwnerOfSummoner(summonerId)) {
            revert("!approved");
        } else {
            _;
        }
    }

    modifier canAttackYet(uint256 summonerId) {
        if (block.timestamp > lastAttack[summonerId] + DAY) {
            _;
        } else {
            revert("!turn");
        }
    }
}
