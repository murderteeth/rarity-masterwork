//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./rarity/Auth.sol";

interface IKoboldBarn {
    function summonerOf(uint256) external view returns (uint256);

    function isEnded(uint256) external view returns (bool);

    function monsterCount(uint256) external view returns (uint256);
}

contract RarityKoboldSalvage is ERC20 {
    IKoboldBarn private koboldBarn;

    mapping(uint256 => bool) public claimedKobolds;

    constructor(IKoboldBarn barn) ERC20("Rarity Kobold Salvage", "RKS") {
        koboldBarn = barn;
    }

    function claim(uint256 summonerId, uint256 instanceId)
        external
        approvedForSummoner(summonerId)
    {
        require(claimedKobolds[instanceId] == false, "!claimed");
        require(koboldBarn.summonerOf(instanceId) == summonerId, "!summoner");
        require(koboldBarn.isEnded(instanceId), "!ended");
        _mint(_msgSender(), koboldBarn.monsterCount(instanceId) * 1e18);
        claimedKobolds[instanceId] = true;
    }

    // Modifiers

    modifier approvedForSummoner(uint256 summonerId) {
        if (Auth.isApprovedOrOwnerOfSummoner(summonerId)) {
            _;
        } else {
            revert("!approved");
        }
    }
}
