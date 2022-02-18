//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/ICodexItemsArmor.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";
import "./core/interfaces/ICrafting.sol";

import "./rarity/Armor.sol";
import "./rarity/Auth.sol";
import "./rarity/Combat.sol";
import "./rarity/FeatCheck.sol";
import "./rarity/SkillCheck.sol";
import "./rarity/Monster.sol";

contract RarityKoboldBarn is ERC721Enumerable {
    uint256 public nextToken = 1;

    uint256 private constant DAY = 1 days;
    uint8 private constant SENSE_MOTIVE_DC = 15;
    uint8 private constant MONSTER_AC = 15;

    // Item contracts for armor and weapons. The items must implement
    // the standard rarity codexes, specifically weapon and armor.
    // We've added an extra boolean to the whitelist to differentiate
    // between standard weapons and masterwork weapons
    struct ItemContract {
        ICrafting theContract;
        bool isMasterwork;
    }
    mapping(address => ItemContract) private itemContracts;

    constructor(ICrafting _masterworkItems) ERC721("Rarity Kobold", "RK") {
        //    Create the item whitelist
        //    Your dungeon could make this list dynamic with an owner function
        //    In our example we keep this static
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
        bool summonerInitiative;
    }

    mapping(uint256 => uint256) public latestFight; // summonerId => koboldId
    mapping(uint256 => Kobold) public kobolds; // tokenId => kobold
    mapping(uint256 => uint256) public lastAttack; // summonerId => timestamp
    mapping(uint256 => uint8) public koboldCount; // summonerId => count

    /*
     * Enter the barn to fight a Kobold
     * Send a weapon and/or armor with your summoner to help
     */
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
        Kobold storage kobold = _startFight(
            summonerId,
            weaponId,
            ICrafting(weaponContract),
            armorId,
            ICrafting(armorContract)
        );
        koboldCount[summonerId]++;
        _fight(kobold, summonerId, true);
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

        Kobold storage latestKobold = kobolds[koboldId];

        // TODO here's a weird scenario - what if this summoner is attacking this
        // kobold, but the kobold battle transferred to another wallet?
        require(_isApprovedOrOwner(_msgSender(), koboldId), "!kobold");

        _fight(latestKobold, summonerId, false);
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

    function _fight(
        Kobold storage kobold,
        uint256 summonerId,
        bool firstAttack
    ) internal {
        lastAttack[summonerId] = block.timestamp;

        if (kobold.summonerInitiative) {
            _summonerAttack(kobold, summonerId, firstAttack);
            _koboldAttack(kobold, summonerId);
        } else {
            _koboldAttack(kobold, summonerId);
            _summonerAttack(kobold, summonerId, firstAttack);
        }
    }

    function _koboldAttack(Kobold storage kobold, uint256 summonerId) internal {
        if (kobold.health > 0) {
            uint8 summonerAC = Armor.class(
                summonerId,
                kobold.armorId,
                kobold.armorContract
            );
            uint8 masterworkArmorBonus = 0;
            if (
                kobold.armorId != 0 &&
                itemContracts[address(kobold.armorContract)].isMasterwork
            ) {
                masterworkArmorBonus = 1;
            }

            // Attack: Spear +1 melee (1d6-1/x3)
            (uint8 kRoll, uint8 kScore, uint8 kDamage) = Monster.basicAttack(
                1,
                1,
                summonerAC + masterworkArmorBonus,
                1,
                6,
                -1,
                3
            );
            console.log("Summoner fwacked with damage", kDamage);
            if (kobold.summonerHealth >= kDamage) {
                kobold.summonerHealth -= kDamage;
            }
            // TODO: emit kobold attack. ouch!
        }
    }

    function _summonerAttack(
        Kobold storage kobold,
        uint256 summonerId,
        bool firstAttack
    ) internal {
        uint8 _monsterAC = MONSTER_AC;
        if (
            firstAttack && SkillCheck.senseMotive(summonerId, SENSE_MOTIVE_DC)
        ) {
            _monsterAC -= 1;
        }
        if (kobold.health > 0) {
            uint8 masterworkWeaponBonus = 0;
            if (
                kobold.weaponId != 0 &&
                itemContracts[address(kobold.weaponContract)].isMasterwork
            ) {
                masterworkWeaponBonus = 1;
            }
            (
                uint8 attackRoll,
                uint8 attackScore,
                uint8 damage,
                uint8 criticalRoll,
                uint8 criticalDamage
            ) = Combat.basicFullAttack(
                    summonerId,
                    kobold.weaponId,
                    kobold.weaponContract,
                    _monsterAC
                );
            // TODO: Emit Attack
            uint8 fullDamage = damage + criticalDamage;
            console.log("Kobold fwacked with damage", fullDamage);
            if (fullDamage > kobold.summonerHealth) {
                kobold.health = 0;
            } else {
                kobold.health -= fullDamage;
            }
        }
    }

    function _startFight(
        uint256 summonerId,
        uint256 weaponId,
        ICrafting weaponContract,
        uint256 armorId,
        ICrafting armorContract
    ) internal returns (Kobold storage) {
        require(koboldCount[summonerId] < 11, "!max");
        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);

        // Sneak attack means the kobold could start with 9 health
        latestFight[summonerId] = newTokenId;
        kobolds[newTokenId].health = _koboldStartingHealth();
        kobolds[newTokenId].summonerId = summonerId;
        kobolds[newTokenId].weaponId = weaponId;
        kobolds[newTokenId].weaponContract = weaponContract;
        kobolds[newTokenId].armorId = armorId;
        kobolds[newTokenId].armorContract = armorContract;

        kobolds[newTokenId].summonerHealth = Combat.summonerHp(summonerId);
        kobolds[newTokenId].enteredAt = block.timestamp;

        kobolds[newTokenId].summonerInitiative =
            Combat.initiative(
                summonerId,
                int8(FeatCheck.initiative(summonerId))
            ) >=
            Monster.initiative(13, 1); // Kobolds have 13 dex, +1 initiative bonus

        lastAttack[summonerId] = block.timestamp;

        nextToken += 1;

        return kobolds[newTokenId];
    }

    function _koboldStartingHealth() internal view returns (uint8) {
        uint8 hp = Monster.hp(1, 8, 4);
        return hp;
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (Auth.isApprovedOrOwnerOfSummoner(summonerId)) {
            _;
        } else {
            revert("!approved");
        }
    }

    modifier canAttackYet(uint256 summonerId) {
        if (block.timestamp > lastAttack[summonerId] + DAY) {
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

    /*
     * Here we determine if the item is valid.
     * First, we make sure if the item expected is a weapon or armor that it is the correct base type per the codex
     * Finally, the item contract must tell us the item is valid
     */
    function validItem(
        uint256 tokenId,
        address itemContract,
        uint256 requiredBase
    ) internal view returns (bool) {
        if (tokenId == 0) {
            return true; // None sent, that's fine
        }
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
