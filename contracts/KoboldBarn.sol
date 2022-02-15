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

    // Helper constants
    uint256 private constant DAY = 1 days;

    mapping(address => ICrafting) private itemContracts;

    constructor(ICrafting _masterworkItems) ERC721("Rarity Kobold", "RK") {
        // Create item whitelist
        itemContracts[0xf41270836dF4Db1D28F7fd0935270e3A603e78cC] = ICrafting(
            0xf41270836dF4Db1D28F7fd0935270e3A603e78cC
        );
        itemContracts[address(_masterworkItems)] = ICrafting(_masterworkItems);
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
    mapping(uint256 => Kobold) public kobolds;
    mapping(uint256 => uint256) public lastAttack;

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
        validItem(weaponId, weaponContract, 3)
        validItem(armorId, armorContract, 2)
    {
        Kobold memory kobold = _startFight(
            summonerId,
            weaponId,
            ICrafting(weaponContract),
            armorId,
            ICrafting(armorContract)
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

    modifier validItem(
        uint256 tokenId,
        address itemContract,
        uint256 requiredBase
    ) {
        (uint8 itemBase, uint8 itemType, , ) = itemContracts[itemContract]
            .items(tokenId);
        if (itemBase != requiredBase) {
            revert("!base");
        } else if (!itemContracts[itemContract].isValid(itemBase, itemType)) {
            revert("!valiid");
        } else if (
            _msgSender() != itemContracts[itemContract].ownerOf(tokenId)
        ) {
            revert("!owner");
        } else {
            _;
        }
    }
}
