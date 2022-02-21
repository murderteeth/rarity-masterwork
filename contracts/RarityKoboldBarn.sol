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

    uint8 public constant MONSTER_AC = 15;
    uint8 public constant MONSTER_HIT_DICE_ROLLS = 1;
    uint8 public constant MONSTER_HIT_DICE_SIDES = 8;
    uint8 public constant MONSTER_HIT_DICE_BONUS = 4;
    uint8 public constant MONSTER_DEX = 13;
    int8 public constant MONSTER_INITIATIVE_BONUS = 1;

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

    struct Instance {
        uint8 health;
        uint256 summonerId;
        uint8 summonerHealth;
        bool hasArmor;
        uint256 armorId;
        ICrafting armorContract;
        bool hasWeapon;
        uint256 weaponId;
        ICrafting weaponContract;
        uint256 enteredAt;
        uint256 lastAttack;
        bool summonerInitiative;
        uint8 monsterCount;
    }

    mapping(uint256 => Instance) public instances;
    mapping(uint256 => uint256) public summonerInstances;

    event Entered(
        address owner,
        uint256 summonerId,
        uint8 summonerHealth,
        uint8 monsterHealth,
        bool hasWeapon,
        uint256 weaponId,
        address weaponContract,
        bool hasArmor,
        uint256 armorId,
        address armorContract
    );

    event SummonerAttack(
        uint256 summonerId,
        uint8 attackRoll,
        uint8 attackScore,
        uint8 damage,
        uint8 criticalRoll,
        uint8 criticalDamage,
        uint8 remainingHealth
    );

    event MonsterAttack(
        uint256 summonerId,
        uint8 attackRoll,
        uint8 attackScore,
        uint8 damage,
        uint8 remainingHealth
    );

    /*
     * Enter the barn to fight Kobolds
     * Send a weapon and/or armor with your summoner to help
     */
    function enter(
        uint256 summonerId,
        bool hasWeapon,
        uint256 weaponId,
        address weaponContract,
        bool hasArmor,
        uint256 armorId,
        address armorContract
    ) external approvedForSummoner(summonerId) {
        require(summonerInstances[summonerId] == 0, "!instance");
        require(
            validItems(
                hasWeapon,
                weaponId,
                weaponContract,
                hasArmor,
                armorId,
                armorContract
            ),
            "!items"
        );
        Instance storage instance = _createInstance(
            summonerId,
            hasWeapon,
            weaponId,
            ICrafting(weaponContract),
            hasArmor,
            armorId,
            ICrafting(armorContract)
        );
        _fight(instance, summonerId);
    }

    /*
    Remove the summoner from its instance
    This will set the summoner's health to 0, as if it lost
     */
    function leave(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
    {
        require(summonerInstances[summonerId] != 0, "!instance");
        instances[summonerInstances[summonerId]].summonerHealth = 0;
    }

    /*
     */
    function attack(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
        canAttackYet(summonerId)
    {
        require(!isEnded(summonerInstances[summonerId]), "!ended");

        // TODO here's a weird scenario - what if this summoner is attacking this
        // kobold, but the kobold battle transferred to another wallet?
        require(
            _isApprovedOrOwner(_msgSender(), summonerInstances[summonerId]),
            "!instance"
        );

        _fight(instances[summonerInstances[summonerId]], summonerId);
    }

    function summonerOf(uint256 instanceId) public view returns (uint256) {
        return instances[instanceId].summonerId;
    }

    function isWon(uint256 instanceId) public view returns (bool) {
        return
            instances[instanceId].enteredAt > 0 &&
            instances[instanceId].health == 0;
    }

    function isEnded(uint256 instanceId) public view returns (bool) {
        console.log("Monster count", instances[instanceId].monsterCount);
        console.log("Summoner health", instances[instanceId].summonerHealth);
        return
            instances[instanceId].monsterCount == 10 ||
            instances[instanceId].summonerHealth == 0;
    }

    function _fight(Instance storage instance, uint256 summonerId) internal {
        instance.lastAttack = block.timestamp;
        uint8 monsterAC = MONSTER_AC;

        if (instance.health == 0) {
            _nextMonster(instance);
            if (SkillCheck.senseMotive(summonerId, SENSE_MOTIVE_DC)) {
                monsterAC -= 1;
            }
        }

        if (instance.summonerInitiative) {
            _summonerAttack(instance, summonerId, monsterAC);
            _monsterAttack(instance, summonerId);
        } else {
            _monsterAttack(instance, summonerId);
            _summonerAttack(instance, summonerId, monsterAC);
        }
    }

    function _monsterAttack(Instance storage instance, uint256 summonerId)
        internal
    {
        if (instance.health > 0) {
            uint8 summonerAC = 0;
            if (instance.hasArmor) {
                summonerAC = Armor.class(
                    summonerId,
                    instance.armorId,
                    instance.armorContract
                );
            }
            uint8 masterworkArmorBonus = 0;
            if (
                instance.hasArmor &&
                itemContracts[address(instance.armorContract)].isMasterwork
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
            if (instance.summonerHealth <= kDamage) {
                instance.summonerHealth = 0;
            } else {
                instance.summonerHealth -= kDamage;
            }
            emit MonsterAttack(
                summonerId,
                kRoll,
                kScore,
                kDamage,
                instance.summonerHealth
            );
        }
    }

    function _summonerAttack(
        Instance storage instance,
        uint256 summonerId,
        uint8 monsterAC
    ) internal {
        if (instance.health > 0) {
            uint8 masterworkWeaponBonus = 0;
            if (
                instance.hasWeapon &&
                itemContracts[address(instance.weaponContract)].isMasterwork
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
                    instance.hasWeapon,
                    instance.weaponId,
                    instance.weaponContract,
                    monsterAC,
                    masterworkWeaponBonus
                );
            if (instance.health <= (damage + criticalDamage)) {
                instance.health = 0;
            } else {
                instance.health -= (damage + criticalDamage);
            }
            emit SummonerAttack(
                summonerId,
                attackRoll,
                attackScore,
                damage,
                criticalRoll,
                criticalDamage,
                instance.health
            );
        }
    }

    function _nextMonster(Instance storage instance) internal {
        instance.monsterCount += 1;
        instance.health = _monsterStartingHealth();
        instance.summonerInitiative =
            Combat.initiative(
                instance.summonerId,
                int8(FeatCheck.initiative(instance.summonerId))
            ) >=
            Monster.initiative(MONSTER_DEX, MONSTER_INITIATIVE_BONUS);
    }

    function _createInstance(
        uint256 summonerId,
        bool hasWeapon,
        uint256 weaponId,
        ICrafting weaponContract,
        bool hasArmor,
        uint256 armorId,
        ICrafting armorContract
    ) internal returns (Instance storage) {
        require(
            instances[summonerInstances[summonerId]].enteredAt == 0,
            "!alreadyEntered"
        );

        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);
        summonerInstances[summonerId] = newTokenId;

        instances[newTokenId].summonerId = summonerId;
        instances[newTokenId].hasWeapon = hasWeapon;
        instances[newTokenId].weaponId = weaponId;
        instances[newTokenId].weaponContract = weaponContract;
        instances[newTokenId].hasArmor = hasArmor;
        instances[newTokenId].armorId = armorId;
        instances[newTokenId].armorContract = armorContract;

        instances[newTokenId].summonerHealth = Combat.summonerHp(summonerId);
        instances[newTokenId].enteredAt = block.timestamp;

        nextToken += 1;

        return instances[newTokenId];
    }

    function _monsterStartingHealth() internal view returns (uint8) {
        uint8 hp = Monster.hp(
            MONSTER_HIT_DICE_ROLLS,
            MONSTER_HIT_DICE_SIDES,
            MONSTER_HIT_DICE_BONUS
        );
        return hp;
    }

    function validItems(
        bool hasWeapon,
        uint256 weaponId,
        address weaponContract,
        bool hasArmor,
        uint256 armorId,
        address armorContract
    ) internal view returns (bool) {
        if (hasWeapon && !validItem(weaponId, weaponContract, 3)) {
            return false;
        } else if (hasArmor && !validItem(armorId, armorContract, 2)) {
            return false;
        } else {
            return true;
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

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (Auth.isApprovedOrOwnerOfSummoner(summonerId)) {
            _;
        } else {
            revert("!approved");
        }
    }

    modifier canAttackYet(uint256 summonerId) {
        if (
            block.timestamp >=
            instances[summonerInstances[summonerId]].lastAttack + DAY
        ) {
            _;
        } else {
            revert("!turn");
        }
    }
}
