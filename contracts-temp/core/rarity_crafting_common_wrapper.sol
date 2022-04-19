//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./rarity_crafting_common.sol";
import "../interfaces/codex/IRarityCodexCommonArmor.sol";
import "../library/Codex.sol";
import "../library/Effects.sol";

interface ICommonCrafting {
  function SUMMMONER_ID() external view returns (uint);
  function approve(address to, uint tokenId) external;
  function balanceOf(address owner) external view returns (uint);
  function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
  function craft_skillcheck(uint _summoner, uint _dc) external view returns (bool crafted, int check);
  function getApproved(uint tokenId) external view returns (address);
  function get_armor_dc(uint _item_id) external pure returns (uint dc);
  function get_dc(uint _base_type, uint _item_id) external pure returns (uint dc);
  function get_goods_dc() external pure returns (uint dc);
  function get_item_cost(uint _base_type, uint _item_type) external pure returns (uint cost);
  function get_token_uri_armor(uint _item) external view returns (string memory output);
  function get_token_uri_goods(uint _item) external view returns (string memory output);
  function get_token_uri_weapon(uint _item) external view returns (string memory output);
  function get_type(uint _type_id) external pure returns (string memory _type);
  function get_weapon_dc(uint _item_id) external pure returns (uint dc);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function isValid(uint _base_type, uint _item_type) external pure returns (bool);
  function items(uint token) external view returns (rarity_crafting.item memory);
  function modifier_for_attribute(uint _attribute) external pure returns (int _modifier);
  function name() external view returns (string memory);
  function next_item() external view returns (uint);
  function ownerOf(uint tokenId) external view returns (address);
  function safeTransferFrom(address from, address to, uint tokenId) external;
  function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
  function setApprovalForAll(address operator, bool approved) external;
  function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function symbol() external view returns (string memory);
  function tokenByIndex(uint index) external view returns (uint);
  function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint);
  function tokenURI(uint _item) external view returns (string memory uri);
  function totalSupply() external view returns (uint);
  function transferFrom(address from, address to, uint tokenId) external;
}

contract rarity_crafting_wrapper is ICommonCrafting, IWeapon, IArmor, IEffects {

  // IWeapon
  ICodexWeapon constant WEAPON_CODEX = ICodexWeapon(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);
  function get_weapon(uint8 item_type) override public pure returns (IWeapon.Weapon memory) {
    return WEAPON_CODEX.item_by_id(item_type);
  }

  // IArmor
  IRarityCodexCommonArmor constant ARMOR_CODEX = IRarityCodexCommonArmor(0xf5114A952Aca3e9055a52a87938efefc8BB7878C);
  function get_armor(uint8 item_type) override public pure returns (IArmor.Armor memory armor) {
    (
      uint id, 
      uint cost, 
      uint proficiency, 
      uint weight, 
      uint armor_bonus, 
      uint max_dex_bonus, 
      int penalty, 
      uint spell_failure, 
      string memory _name, 
      string memory description
    ) = ARMOR_CODEX.item_by_id(item_type);
    armor.id = uint8(id);
    armor.proficiency = uint8(proficiency);
    armor.weight = uint8(weight);
    armor.armor_bonus = uint8(armor_bonus);
    armor.max_dex_bonus = uint8(max_dex_bonus);
    armor.penalty = int8(penalty);
    armor.spell_failure = uint8(spell_failure);
    armor.cost = cost;
    armor.name = _name;
    armor.description = description;
  }

  // IEffects
  function armor_check_bonus(uint token) override external pure returns (int8 result) { token; result = 0; }
  function attack_bonus(uint token) override external pure returns (int8 result) { token; result = 0; }
  function skill_bonus(uint token, uint8 skill) override external pure returns (int8 result) { token; skill; result = 0; }

  // ICommonCrafting
  ICommonCrafting public constant COMMON_CRAFTING = ICommonCrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

  function SUMMMONER_ID() override public view returns (uint) { 
    return COMMON_CRAFTING.SUMMMONER_ID(); 
  }

  function approve(address to, uint tokenId) override public { 
    COMMON_CRAFTING.approve(to, tokenId);
  }

  function balanceOf(address owner) override public view returns (uint) {
    return COMMON_CRAFTING.balanceOf(owner);
  }

  function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) override external {
    COMMON_CRAFTING.craft(_summoner, _base_type, _item_type, _crafting_materials);
  }

  function craft_skillcheck(uint _summoner, uint _dc) override public view returns (bool crafted, int check) {
    return COMMON_CRAFTING.craft_skillcheck(_summoner, _dc);
  }

  function getApproved(uint tokenId) override public view returns (address) {
    return COMMON_CRAFTING.getApproved(tokenId);
  }

  function get_armor_dc(uint _item_id) override public pure returns (uint dc) {
    return COMMON_CRAFTING.get_armor_dc(_item_id);
  }

  function get_dc(uint _base_type, uint _item_id) override public pure returns (uint dc) {
    return COMMON_CRAFTING.get_dc(_base_type, _item_id);
  }

  function get_goods_dc() override public pure returns (uint dc) {
    return COMMON_CRAFTING.get_goods_dc();
  }

  function get_item_cost(uint _base_type, uint _item_type) override public pure returns (uint cost) {
    return COMMON_CRAFTING.get_item_cost(_base_type, _item_type);
  }

  function get_token_uri_armor(uint _item) override public view returns (string memory output) {
    return COMMON_CRAFTING.get_token_uri_armor(_item);
  }

  function get_token_uri_goods(uint _item) override public view returns (string memory output) {
    return COMMON_CRAFTING.get_token_uri_goods(_item);
  }

  function get_token_uri_weapon(uint _item) override public view returns (string memory output) {
    return COMMON_CRAFTING.get_token_uri_weapon(_item);
  }

  function get_type(uint _type_id) override public pure returns (string memory _type) {
    return COMMON_CRAFTING.get_type(_type_id);
  }

  function get_weapon_dc(uint _item_id) override public pure returns (uint dc) {
    return COMMON_CRAFTING.get_weapon_dc(_item_id);
  }

  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    return COMMON_CRAFTING.isApprovedForAll(owner, operator);
  }

  function isValid(uint _base_type, uint _item_type) override public pure returns (bool) {
    return COMMON_CRAFTING.isValid(_base_type, _item_type);
  }

  function items(uint token) override public view returns (rarity_crafting.item memory) {
    return COMMON_CRAFTING.items(token);
  }

  function modifier_for_attribute(uint _attribute) override public pure returns (int _modifier) {
    return COMMON_CRAFTING.modifier_for_attribute(_attribute);
  }

  function name() override public view returns (string memory) {
    return COMMON_CRAFTING.name();
  }

  function next_item() override public view returns (uint) {
    return COMMON_CRAFTING.next_item();
  }

  function ownerOf(uint tokenId) override public view returns (address) {
    return COMMON_CRAFTING.ownerOf(tokenId);
  }

  function safeTransferFrom(address from, address to, uint tokenId) override public {
    COMMON_CRAFTING.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) override public {
    COMMON_CRAFTING.safeTransferFrom(from, to, tokenId, _data);
  }

  function setApprovalForAll(address operator, bool approved) override public {
    COMMON_CRAFTING.setApprovalForAll(operator, approved);
  }

  function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) override external view returns (bool crafted, int check, uint cost, uint dc) {
    return COMMON_CRAFTING.simulate(_summoner, _base_type, _item_type, _crafting_materials);
  }

  function supportsInterface(bytes4 interfaceId) override public view returns (bool) {
    return COMMON_CRAFTING.supportsInterface(interfaceId);
  }

  function symbol() override public view returns (string memory) {
    return COMMON_CRAFTING.symbol();
  }

  function tokenByIndex(uint index) override public view returns (uint) {
    return COMMON_CRAFTING.tokenByIndex(index);
  }

  function tokenOfOwnerByIndex(address owner, uint index) override public view returns (uint) {
    return COMMON_CRAFTING.tokenOfOwnerByIndex(owner, index);
  }

  function tokenURI(uint _item) override public view returns (string memory uri) {
    return COMMON_CRAFTING.tokenURI(_item);
  }

  function totalSupply() override public view returns (uint) {
    return COMMON_CRAFTING.totalSupply();
  }

  function transferFrom(address from, address to, uint tokenId) override public {
    COMMON_CRAFTING.transferFrom(from, to, tokenId);
  }
}