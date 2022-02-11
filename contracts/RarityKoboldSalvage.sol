//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./utils/RarityOwnership.sol";

interface IKoboldBarn {
    function kobolds(uint256)
        external
        view
        returns (
            uint8 health,
            uint256 koboldId,
            uint8 summonerHealth,
            uint256 armorId,
            uint256 weaponId,
            uint256 lastTurn,
            bool masterwork
        );
}

contract RarityKoboldSalvage is ERC20 {
    mapping(uint256 => bool) public claimedKobolds;

    constructor() ERC20("Rarity Kobold Salvage", "RKS") {}

    function claim(uint256 summonerId, uint256 koboldId)
        external
        approvedForSummoner(summonerId)
    {}

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (RarityOwnership._isApprovedOrOwnerOfSummoner(summonerId)) {
            revert("!approved");
        } else {
            _;
        }
    }
}
