//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./utils/RaritySkillCheck.sol";
import "./utils/Rarity.sol";

contract KoboldBarn is ERC721Enumerable {
    uint256 public nextToken = 1;

    // Helper constants
    uint256 private constant DAY = 1 days;

    constructor() ERC721("Rarity Kobold", "RK") {}

    struct Kobold {
        uint8 health;
        uint256 summonerId;
        uint8 summonerHealth;
        uint256 armorId;
        uint256 weaponId;
        uint256 lastTurn;
        bool masterwork;
    }

    mapping(uint256 => uint256) public latestFight; // summonerId => koboldId
    mapping(uint256 => Kobold) public kobolds;

    // Attack to start or continue a fight
    function attack(uint256 summonerId)
        external
        approvedForSummoner(summonerId)
    {
        // Get the summoner's latest kobold
        uint256 koboldId = latestFight[summonerId];
        Kobold memory latestKobold = kobolds[koboldId];

        if (latestKobold.health == 0 || latestKobold.summonerHealth == 0) {
            // Pick a fight with a new Kobold
            Kobold memory newKobold = _startFight(summonerId);

            _fight(newKobold, summonerId);
        } else {
            require(_isApprovedOrOwner(_msgSender(), koboldId), "!kobold");
            // Summoners can only attack once per day
            require(block.timestamp > latestKobold.lastTurn + DAY, "!turn");

            _fight(latestKobold, summonerId);
        }
    }

    function summonerOf(uint256 koboldId) public view returns (uint256) {
        return kobolds[koboldId].summonerId;
    }

    function isWon(uint256 koboldId) public pure returns (bool) {
        // TODO
        return true;
    }

    function _fight(Kobold memory kobold, uint256 summonerId) internal {
        //
        // If success...
        // KOBOLD_SALVAGE.mint(_msgSender(), 1);
    }

    function _startFight(uint256 summonerId) internal returns (Kobold memory) {
        uint256 newTokenId = nextToken;
        _safeMint(_msgSender(), newTokenId);

        // Sneak attack means the kobold could start with 9 health
        latestFight[summonerId] = newTokenId;
        kobolds[newTokenId].health = _koboldStartingHealth(summonerId);
        kobolds[newTokenId].summonerId = summonerId;

        kobolds[newTokenId].summonerHealth = Rarity.health(summonerId);

        kobolds[newTokenId].lastTurn = block.timestamp;

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
}
