//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./utils/RarityHelpers.sol";

interface IKoboldBarn {
    function summonerOf(uint256) external view returns (uint256);

    function isWon(uint256) external view returns (bool);
}

contract RarityKoboldSalvage is ERC20 {
    IKoboldBarn private koboldBarn;

    mapping(uint256 => bool) public claimedKobolds;

    constructor(IKoboldBarn barn) ERC20("Rarity Kobold Salvage", "RKS") {
        koboldBarn = barn;
    }

    function claim(uint256 summonerId, uint256 koboldId)
        external
        approvedForSummoner(summonerId)
    {
        require(claimedKobolds[koboldId] == false, "!claimed");
        require(koboldBarn.summonerOf(koboldId) == summonerId, "!summoner");
        require(koboldBarn.isWon(koboldId), "!won");
        _mint(_msgSender(), 1);
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (RarityHelpers._isApprovedOrOwnerOfSummoner(summonerId)) {
            revert("!approved");
        } else {
            _;
        }
    }
}
