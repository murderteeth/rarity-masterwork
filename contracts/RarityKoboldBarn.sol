//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./core/interfaces/ICodexItemsArmor.sol";
import "./core/interfaces/ICodexItemsWeapons.sol";
import "./core/interfaces/ICrafting.sol";

import "./rarity/Armor.sol";
import "./rarity/Combat.sol";
import "./rarity/FeatCheck.sol";
import "./rarity/RarityBase.sol";
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

    /* Item contracts for armor and weapons. The items must implement
     * the standard rarity codexes, specifically weapon and armor.
     * We've added an extra boolean to the whitelist to differentiate
     * between standard weapons and masterwork weapons
     */
    struct ItemContract {
        ICrafting theContract;
        bool isMasterwork;
    }
    mapping(address => ItemContract) private itemContracts;

    constructor(ICrafting _masterworkItems) ERC721("Rarity Kobold", "RK") {
        /* Create the item whitelist
         * Your dungeon could make this list dynamic with an owner function
         * In our example we keep this static
         */
        itemContracts[0xf41270836dF4Db1D28F7fd0935270e3A603e78cC]
            .theContract = ICrafting(
            0xf41270836dF4Db1D28F7fd0935270e3A603e78cC
        );
        itemContracts[address(_masterworkItems)].theContract = ICrafting(
            _masterworkItems
        );
        itemContracts[address(_masterworkItems)].isMasterwork = true;
    }

    struct Encounter {
        uint8 health; // Health of the monster that is currently engaged with
        uint256 summonerId; // ID of the summoner in this encounter
        uint8 summonerHealth; // Summoner health
        bool hasArmor; // If the summoner was sent with armor
        uint256 armorId; // The armor token ID
        ICrafting armorContract; // Armor contract must comply with ICrafting
        bool hasWeapon;
        uint256 weaponId;
        ICrafting weaponContract;
        uint256 enteredAt;
        uint256 lastAttack;
        bool summonerInitiative;
        uint8 monsterCount;
    }

    mapping(uint256 => Encounter) public encounters;
    mapping(uint256 => uint256) public summonerEncounters;

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
        int8 attackScore,
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
        require(summonerEncounters[summonerId] == 0, "!encounter");
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
        Encounter storage encounter = _createEncounter(
            summonerId,
            hasWeapon,
            weaponId,
            ICrafting(weaponContract),
            hasArmor,
            armorId,
            ICrafting(armorContract)
        );
        _fight(encounter, summonerId, true);
    }

    /*
     * Remove the summoner from its encounter
     * This will set the summoner's health to 0, as if it lost
     */
    function leave(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
    {
        require(summonerEncounters[summonerId] != 0, "!encounter");
        encounters[summonerEncounters[summonerId]].summonerHealth = 0;
    }

    /*
     * The main attack function. Since any summoner can only have a single encounter,
     * we only need to know the summoner token id.
     */
    function attack(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
        canAttackYet(summonerId)
    {
        require(!isEnded(summonerEncounters[summonerId]), "!ended");

        // A bit of a race condition for people who sell/transfer their
        // summoner if in the middle of an encounter may well not be able
        // to finish, since the encounter is not automatically transferred
        require(
            _isApprovedOrOwner(_msgSender(), summonerEncounters[summonerId]),
            "!encounter"
        );

        _fight(encounters[summonerEncounters[summonerId]], summonerId, false);
    }

    /*
     * Helper - How many monsters have been defeated in this encounter?
     */
    function monsterCount(uint256 encounterId) public view returns (uint256) {
        return encounters[encounterId].monsterCount;
    }

    /*
     * Helper - Whose summoner is this encounter?
     */
    function summonerOf(uint256 encounterId) public view returns (uint256) {
        return encounters[encounterId].summonerId;
    }

    /*
     * Helper - The encounter is over once the summoner has defeated 10
     * kobold monsters or the summoner has been knocked out.
     */
    function isEnded(uint256 encounterId) public view returns (bool) {
        return
            encounters[encounterId].monsterCount == 10 ||
            encounters[encounterId].summonerHealth == 0;
    }

    function _fight(
        Encounter storage encounter,
        uint256 summonerId,
        bool firstEncounter
    ) internal {
        encounter.lastAttack = block.timestamp;
        uint8 monsterAC = MONSTER_AC;

        if (encounter.health == 0) {
            _nextMonster(encounter);
            if (
                firstEncounter &&
                SkillCheck.senseMotive(summonerId, SENSE_MOTIVE_DC)
            ) {
                monsterAC -= 1;
            }
        }

        if (encounter.summonerInitiative) {
            _summonerAttack(encounter, summonerId, monsterAC);
            _monsterAttack(encounter, summonerId);
        } else {
            _monsterAttack(encounter, summonerId);
            _summonerAttack(encounter, summonerId, monsterAC);
        }
    }

    function _monsterAttack(Encounter storage encounter, uint256 summonerId)
        internal
    {
        if (encounter.health > 0) {
            uint8 summonerAC = 0;
            if (encounter.hasArmor) {
                summonerAC = Armor.class(
                    summonerId,
                    encounter.armorId,
                    address(encounter.armorContract)
                );
            }
            uint8 masterworkArmorBonus = 0;
            if (
                encounter.hasArmor &&
                itemContracts[address(encounter.armorContract)].isMasterwork
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
            if (encounter.summonerHealth <= kDamage) {
                encounter.summonerHealth = 0;
            } else {
                encounter.summonerHealth -= kDamage;
            }
            emit MonsterAttack(
                summonerId,
                kRoll,
                kScore,
                kDamage,
                encounter.summonerHealth
            );
        }
    }

    function _summonerAttack(
        Encounter storage encounter,
        uint256 summonerId,
        uint8 monsterAC
    ) internal {
        if (encounter.health > 0) {
            int8 masterworkWeaponBonus = 0;
            if (
                encounter.hasWeapon &&
                itemContracts[address(encounter.weaponContract)].isMasterwork
            ) {
                masterworkWeaponBonus = 1;
            }
            (
                uint8 attackRoll,
                int8 attackScore,
                uint8 damage,
                uint8 criticalRoll,
                uint8 criticalDamage
            ) = _basicFullAttack(
                    summonerId,
                    encounter,
                    monsterAC,
                    masterworkWeaponBonus
                );
            if (encounter.health <= (damage + criticalDamage)) {
                encounter.health = 0;
            } else {
                encounter.health -= (damage + criticalDamage);
            }
            emit SummonerAttack(
                summonerId,
                attackRoll,
                attackScore,
                damage,
                criticalRoll,
                criticalDamage,
                encounter.health
            );
        }
    }

    function _basicFullAttack(
        uint256 summonerId,
        Encounter memory encounter,
        uint8 targetAC,
        int8 weaponBonus
    )
        internal
        view
        returns (
            uint8 attackRoll,
            int8 attackScore,
            uint8 damage,
            uint8 criticalRoll,
            uint8 criticalDamage
        )
    {
        int8 armorProficiencyBonus = Armor.proficiencyBonus(
            summonerId,
            encounter.hasArmor,
            encounter.armorId,
            address(encounter.armorContract)
        );
        return
            Combat.basicFullAttack(
                summonerId,
                encounter.hasWeapon,
                encounter.weaponId,
                encounter.weaponContract,
                targetAC,
                weaponBonus,
                armorProficiencyBonus
            );
    }

    function _nextMonster(Encounter storage encounter) internal {
        encounter.monsterCount += 1;
        encounter.health = _monsterStartingHealth();
    }

    function _createEncounter(
        uint256 summonerId,
        bool hasWeapon,
        uint256 weaponId,
        ICrafting weaponContract,
        bool hasArmor,
        uint256 armorId,
        ICrafting armorContract
    ) internal returns (Encounter storage) {
        require(
            encounters[summonerEncounters[summonerId]].enteredAt == 0,
            "!alreadyEntered"
        );

        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);
        summonerEncounters[summonerId] = newTokenId;

        encounters[newTokenId].summonerId = summonerId;
        encounters[newTokenId].hasWeapon = hasWeapon;
        encounters[newTokenId].weaponId = weaponId;
        encounters[newTokenId].weaponContract = weaponContract;
        encounters[newTokenId].hasArmor = hasArmor;
        encounters[newTokenId].armorId = armorId;
        encounters[newTokenId].armorContract = armorContract;
        encounters[newTokenId].summonerInitiative =
            Combat.initiative(
                summonerId,
                int8(FeatCheck.initiative(summonerId)),
                Armor.proficiencyBonus(
                    summonerId,
                    hasArmor,
                    armorId,
                    address(armorContract)
                )
            ) >=
            Monster.initiative(MONSTER_DEX, MONSTER_INITIATIVE_BONUS);

        encounters[newTokenId].summonerHealth = Combat.summonerHp(summonerId);
        encounters[newTokenId].enteredAt = block.timestamp;

        nextToken += 1;

        return encounters[newTokenId];
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
        if (RarityBase.isApprovedOrOwnerOfSummoner(summonerId)) {
            _;
        } else {
            revert("!approved");
        }
    }

    modifier canAttackYet(uint256 summonerId) {
        if (
            block.timestamp >=
            encounters[summonerEncounters[summonerId]].lastAttack + DAY
        ) {
            _;
        } else {
            revert("!turn");
        }
    }
}
