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
import "./rarity/SkillCheck.sol";
import "./rarity/Monster.sol";

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
        Kobold storage kobold = _startFight(
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

        Kobold storage latestKobold = kobolds[koboldId];

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

    function _fight(Kobold storage kobold, uint256 summonerId) internal {
        lastAttack[summonerId] = block.timestamp;
        // SUMMONER DAMAGE TO KOBOLD
        uint8 masterworkWeaponBonus = 0;
        if (itemContracts[address(kobold.weaponContract)].isMasterwork) {
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
                15
            );
        // TODO: Emit Attack
        uint8 fullDamage = damage + criticalDamage;
        console.log("Kobold fwacked with damage", fullDamage);
        if (fullDamage > kobold.summonerHealth) {
            kobold.health = 0;
        } else {
            kobold.health -= fullDamage;
        }

        if (kobold.health > 0) {
            uint8 summonerAC = Armor.class(
                summonerId,
                kobold.armorId,
                kobold.armorContract
            );
            uint8 masterworkArmorBonus = 0;
            if (itemContracts[address(kobold.armorContract)].isMasterwork) {
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

    function _startFight(
        uint256 summonerId,
        uint256 weaponId,
        ICrafting weaponContract,
        uint256 armorId,
        ICrafting armorContract
    ) internal returns (Kobold storage) {
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

        kobolds[newTokenId].summonerHealth = Combat.summonerHp(summonerId);
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
        uint8 hp = Monster.hp(1, 8, 4);
        if (SkillCheck.senseMotive(summonerId, 15)) {
            return hp - 1;
        } else {
            return hp;
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
