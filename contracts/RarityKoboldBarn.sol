//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/ICodexItemsArmor.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";
import "./core/interfaces/ICrafting.sol";

import "./utils/RarityAuth.sol";
import "./utils/RarityCombat.sol";
import "./utils/RaritySkillCheck.sol";
import "./utils/RarityMonster.sol";

contract RarityKoboldBarn is ERC721Enumerable {
    uint256 public nextToken = 1;

    // Helper constants
    uint256 private constant DAY = 1 days;
    uint8 private constant SNEAK_DC = 15;
    uint8 private constant KOBOLD_DC = 15;

    struct ItemContract {
        ICrafting theContract;
        bool isMasterwork;
    }

    mapping(address => ItemContract) private itemContracts;

    constructor(ICrafting _masterworkItems) ERC721("Rarity Kobold", "RK") {
        // Create item whitelist
        itemContracts[0xf41270836dF4Db1D28F7fd0935270e3A603e78cC]
            .theContract = ICrafting(
            0xf41270836dF4Db1D28F7fd0935270e3A603e78cC
        );
        itemContracts[address(_masterworkItems)].theContract = ICrafting(
            _masterworkItems
        );
        itemContracts[address(_masterworkItems)].isMasterwork = true;
    }

    struct Kobold {
        uint8 health;
        uint256 summonerId;
        uint8 summonerHealth;
        uint256 armorId;
        ICrafting armorContract;
        uint256 weaponId;
        ICrafting weaponContract;
        uint256 enteredAt;
    }

    mapping(uint256 => uint256) public latestFight; // summonerId => koboldId
    mapping(uint256 => Kobold) public kobolds; // tokenId => kobold
    mapping(uint256 => uint256) public lastAttack; // summonerId => timestamp
    mapping(uint256 => uint8) public koboldCount; // summonerId => count

    function enter(
        uint256 summonerId,
        uint256 weaponId,
        address weaponContract,
        uint256 armorId,
        address armorContract
    )
        external
        approvedForSummoner(summonerId)
        canAttackYet(summonerId)
        validItems(weaponId, weaponContract, armorId, armorContract)
    {
        Kobold memory kobold = _startFight(
            summonerId,
            weaponId,
            ICrafting(weaponContract),
            armorId,
            ICrafting(armorContract)
        );
        koboldCount[summonerId]++;
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
        // SUMMONER DAMAGE TO KOBOLD
        // 1. Base attack bonus by class and level
        // 2. Strength modifier (for use later)
        // 3. Attack score is 1 + 2 (+1 for masterwork)
        // 4. Add strength modifier to attack score if weapon encumbrance > 0
        // 5. Armor class of Kobold is 15
        // 6. If attack roll is perfect (20) or attack score >= 15
        // 7. Regular damage = 1 to (weapon damage stat) + strength modifier
        // 8. Regular damage must be at least 1
        // 9. If attack roll is 20 congrats - you got a critical hit
        // 10. Confirm critical with d20 + base attack bonus
        // 11. If critical success and weapon encumbrance > 0, add strength modifier to critical confirmation
        // 12. If critical roll > 1 and confirmation >= 15 (Kobold AC)
        //     Roll to determine critical damage and add it plus strength modifier as many times as the weapon's critical
        // 13. HP of Kobold is reduced by regular damage plus critical damage

        // IF KOBOLD IS STILL ALIVE
        // Armor Class: 15
        // Attack: Spear +1 melee (1d6-1/x3)
        // 1. Base attack = level 1, sourcerer (10) 2
        // 2. Str is 9, so modifier is 1
        // 3. Attack score is 1 + 3 = 4
        // 4. Weapon is a +1 spear
        // 5. Armor class of summoner 0 if no armor, 10 + armor bonus + dexterity modifier (not above max as specified by the armor) (+1 for masterwork)
        // 6. If attack roll is perfect or attack score > summoner AC, (1d6-1)*3
        // 7. HP of summoner is reduced by this amount

        int32 masterworkWeaponBonus = 0;
        if (itemContracts[address(kobold.weaponContract)].isMasterwork) {
            masterworkWeaponBonus = 1;
        }
    }

    function _startFight(
        uint256 summonerId,
        uint256 weaponId,
        ICrafting weaponContract,
        uint256 armorId,
        ICrafting armorContract
    ) internal returns (Kobold memory) {
        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);

        // Sneak attack means the kobold could start with 9 health
        latestFight[summonerId] = newTokenId;
        kobolds[newTokenId].health = _koboldStartingHealth(summonerId);
        kobolds[newTokenId].summonerId = summonerId;
        kobolds[newTokenId].weaponId = weaponId;
        kobolds[newTokenId].weaponContract = weaponContract;
        kobolds[newTokenId].armorId = armorId;
        kobolds[newTokenId].armorContract = armorContract;

        kobolds[newTokenId].summonerHealth = RarityCombat.summonerHp(
            summonerId
        );
        kobolds[newTokenId].enteredAt = block.timestamp;

        lastAttack[summonerId] = block.timestamp;

        nextToken += 1;

        return kobolds[newTokenId];
    }

    function _koboldStartingHealth(uint256 summonerId)
        internal
        view
        returns (uint8)
    {
        uint8 hp = RarityMonster.hp(1, 8, 4);
        if (RaritySkillCheck.senseMotive(summonerId, 15)) {
            return hp - 1;
        } else {
            return hp;
        }
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (RarityAuth.isApprovedOrOwnerOfSummoner(summonerId)) {
            _;
        } else {
            revert("!approved");
        }
    }

    modifier canAttackYet(uint256 summonerId) {
        if (
            block.timestamp > lastAttack[summonerId] + DAY &&
            koboldCount[summonerId] < 11
        ) {
            _;
        } else {
            revert("!turn");
        }
    }

    modifier validItems(
        uint256 weaponId,
        address weaponContract,
        uint256 armorId,
        address armorContract
    ) {
        if (!validItem(weaponId, weaponContract, 3)) {
            revert("!weapon");
        } else if (!validItem(armorId, armorContract, 2)) {
            revert("!armor");
        } else {
            _;
        }
    }

    function validItem(
        uint256 tokenId,
        address itemContract,
        uint256 requiredBase
    ) internal view returns (bool) {
        (uint8 itemBase, uint8 itemType, , ) = itemContracts[itemContract]
            .theContract
            .items(tokenId);
        if (
            itemBase != requiredBase ||
            !itemContracts[itemContract].theContract.isValid(itemBase, itemType)
        ) {
            return false;
        } else if (
            _msgSender() !=
            itemContracts[itemContract].theContract.ownerOf(tokenId)
        ) {
            return false;
        } else {
            return true;
        }
    }
}
