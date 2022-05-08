//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/Codex.sol";
import "../library/Combat.sol";
import "../library/Crafting.sol";
import "../library/Equipment.sol";
import "../library/ForItems.sol";
import "../library/ForSummoners.sol";
import "../library/Proficiency.sol";
import "hardhat/console.sol";

contract rarity_equipment_2 is ERC721Holder, ReentrancyGuard, ForSummoners, ForItems {
  address public constant COMMON_CRAFTING = address(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  address[3] public MINT_WHITELIST = [COMMON_CRAFTING, address(0), address(0)];

  mapping(uint => mapping(uint => Equipment.Slot)) public slots;
  mapping(uint => uint) public encumberance;
  mapping(address => mapping(uint => address)) public codexes;

  function set_mint_whitelist(
    address common_wrapper, 
    address common_armor_codex,
    address common_weapon_codex, 
    address masterwork,
    address masterwork_armor_codex,
    address masterwork_weapon_codex
  ) public {
    require(MINT_WHITELIST[1] == address(0), "already set");

    MINT_WHITELIST[1] = common_wrapper;
    codexes[COMMON_CRAFTING][2] = common_armor_codex;
    codexes[common_wrapper][2] = common_armor_codex;
    codexes[COMMON_CRAFTING][3] = common_weapon_codex;
    codexes[common_wrapper][3] = common_weapon_codex;

    MINT_WHITELIST[2] = masterwork;
    codexes[masterwork][2] = masterwork_armor_codex;
    codexes[masterwork][3] = masterwork_weapon_codex;

    // IERC721 common = IERC721(COMMON_CRAFTING);
    // common.setApprovalForAll(common_wrapper, true);
  }

  function whitelisted(address mint) internal view returns (bool) {
    return mint == MINT_WHITELIST[0]
    || mint == MINT_WHITELIST[1]
    || mint == MINT_WHITELIST[2];
  }

  function equip(
    uint summoner, 
    uint slot_type, 
    address mint, 
    uint token
  ) public 
    approvedForSummoner(summoner)
    approvedForItem(token, mint)
  {
    require(whitelisted(mint), "!whitelisted");
    require(slot_type < 3, "!supported");
    require(slots[summoner][slot_type].mint == address(0), "!slotAvailable");
    mint = wrap(mint);

    (uint8 base_type, uint8 item_type,,) = ICrafting(mint).items(token);

    if(slot_type == Equipment.SLOT_TYPE_WEAPON_1) {
      require(base_type == 3, "!weapon");
      IWeapon.Weapon memory weapon = ICodexWeapon(codexes[mint][base_type]).item_by_id(item_type);
      if(weapon.encumbrance == 5) revert("ranged weapon");
      if(weapon.encumbrance == 4) {
        Equipment.Slot memory shield_slot = slots[summoner][Equipment.SLOT_TYPE_SHIELD];
        if(shield_slot.mint != address(0)) revert("shield equipped");
      }

    } else if(slot_type == Equipment.SLOT_TYPE_ARMOR) {
      require(base_type == 2 && item_type < 13, "!armor");

    } else if(slot_type == Equipment.SLOT_TYPE_SHIELD) {
      require(base_type == 2 && item_type > 12, "!shield");
      Equipment.Slot memory weapon_slot = slots[summoner][Equipment.SLOT_TYPE_WEAPON_1];
      if(weapon_slot.mint != address(0)) {
        (,uint8 weapon_type,,) = ICrafting(weapon_slot.mint).items(weapon_slot.token);
        IWeapon.Weapon memory equipped_weapon = ICodexWeapon(codexes[weapon_slot.mint][3]).item_by_id(weapon_type);
        require(equipped_weapon.encumbrance < 4, "two-handed or ranged weapon equipped");
      }
    }

    slots[summoner][slot_type] = Equipment.Slot(mint, token);
    encumberance[summoner] += weigh(mint, base_type, item_type);

    IERC721(mint).safeTransferFrom(msg.sender, address(this), token);
    // IERC721(mint).approve(msg.sender, item);
  }

  function unequip(
    uint summoner,
    uint slot_type
  ) public 
    nonReentrant()
    approvedForSummoner(summoner)
  {
    require(slots[summoner][slot_type].mint != address(0), "slotAvailable");

    Equipment.Slot memory slot = slots[summoner][slot_type];
    (uint8 base_type, uint8 item_type,,) = ICrafting(slot.mint).items(slot.token);
    encumberance[summoner] -= weigh(slot.mint, base_type, item_type);
    delete slots[summoner][slot_type];

    IERC721(slot.mint).safeTransferFrom(address(this), msg.sender, slot.token);
  }

  function wrap(address mint) internal view returns (address) {
    if(mint == COMMON_CRAFTING) return MINT_WHITELIST[1];
    return mint;
  }

  function weigh(address mint, uint base_type, uint8 item_type) internal view returns (uint weight) {
    if(base_type == 2) {
      return ICodexArmor(codexes[mint][base_type]).item_by_id(item_type).weight;
    } else if(base_type == 3) {
      return ICodexWeapon(codexes[mint][base_type]).item_by_id(item_type).weight;
    }
  }
}