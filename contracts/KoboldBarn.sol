//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./utils/RaritySkillCheck.sol";
import "./utils/RarityOwnership.sol";

import "./core/interfaces/IRarity.sol";
import "./core/interfaces/IMaterials.sol";
import "./core/interfaces/IAttributes.sol";

contract KoboldBarn is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private nextTokenId;

    IMaterials private constant MATERIALS =
        IMaterials(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);
    IAttributes private constant ATTRIBUTES =
        IAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    // Helper constants
    uint256 private constant DAY = 1 days;

    constructor() ERC721("Rarity Kobold", "RK") {}

    struct Kobold {
        uint8 health;
        uint256 koboldId;
        uint8 summonerHealth;
        uint256 armorId;
        uint256 weaponId;
        uint256 lastTurn;
        bool masterwork;
    }

    mapping(uint256 => Kobold) public kobolds; // summonerId => Kobold - the kobold the summoner is fighting

    // Attack to start or continue a fight
    function attack(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
    {
        // Get the summoner's latest kobold
        Kobold memory latestKobold = kobolds[summonerId];

        if (latestKobold.health == 0 || latestKobold.summonerHealth == 0) {
            // Pick a fight with a new Kobold
            Kobold memory newKobold = _startFight(summonerId);

            _fight(newKobold, summonerId);
        } else {
            uint256 koboldId = latestKobold.koboldId;
            require(_isApprovedOrOwner(_msgSender(), koboldId), "!kobold");
            // Summoners can only attack once per day
            require(block.timestamp > latestKobold.lastTurn + DAY, "!turn");

            _fight(latestKobold, summonerId);
        }
    }

    function _fight(Kobold memory kobold, uint256 summonerId) internal {
        //
        // If success...
        // KOBOLD_SALVAGE.mint(_msgSender(), 1);
    }

    function _startFight(uint256 summonerId) internal returns (Kobold memory) {
        uint256 newTokenId = nextTokenId.current();
        _safeMint(_msgSender(), newTokenId);

        // Sneak attack means the kobold could start with 9 health
        kobolds[summonerId].health = _koboldStartingHealth(summonerId);
        kobolds[summonerId].koboldId = newTokenId;

        kobolds[summonerId].summonerHealth = _summonerStartingHealth(
            summonerId
        );

        kobolds[summonerId].lastTurn = block.timestamp;

        nextTokenId.increment();

        return kobolds[summonerId];
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

    function _summonerStartingHealth(uint256 summonerId)
        internal
        view
        returns (uint8)
    {
        uint256 _level = RarityOwnership.rm().level(summonerId);
        uint256 _class = RarityOwnership.rm().class(summonerId);
        (, , uint32 _const, , , ) = ATTRIBUTES.ability_scores(summonerId);
        return
            uint8(MATERIALS.health_by_class_and_level(_class, _level, _const));
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (RarityOwnership._isApprovedOrOwnerOfSummoner(summonerId)) {
            revert("!approved");
        } else {
            _;
        }
    }
}
