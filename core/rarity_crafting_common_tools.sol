//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/IRarity.sol";
import "../interfaces/IRarityCraftingCommon.sol";
import "../library/ForSummoners.sol";

interface IToolsCodex {
  struct effects_struct {
    int[36] skill_bonus;
  }

  function item_by_id(uint _id) external pure returns(
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    effects_struct memory effects
  );

  function artisans_tools() external pure returns (
    uint8 id,
    uint cost,
    uint weight,
    string memory name,
    string memory description,
    effects_struct memory effects
  );
}

interface IEffects {
  function skill_bonus(uint token, uint8 skill) external view returns (int);
}

contract rarity_crafting_tools is ForSummoners, ERC721Enumerable, IEffects {
  uint8 public constant base_type = 4; //tools
  uint public next_token = 1;

  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityCraftingCommon common_crafting = IRarityCraftingCommon(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  IToolsCodex tools_codex = IToolsCodex(0x000000000000000000000000000000000000dEaD);

  event Exchanged(address indexed owner, uint token_id, uint summoner, uint8 base_type, uint8 item_type, uint exchanged_item);

  constructor() ERC721("Rarity Common Tools", "RC(I) Tools") {}

  struct Item {
    uint8 base_type;
    uint8 item_type;
    uint32 crafted;
    uint crafter;
  }

  mapping(uint => Item) public items;

  function skill_bonus(uint token, uint8 skill) override external view returns (int) {
    Item memory item = items[token];
    (,,,,,IToolsCodex.effects_struct memory effects) = tools_codex.item_by_id(item.item_type);
    return effects.skill_bonus[skill];
  }

  function exchange(uint summoner, uint item_to_exchange) external approvedForSummoner(summoner) {
    (uint8 tools_id, uint tools_cost,,,,) = tools_codex.artisans_tools();

    (uint8 item_to_exchange_base_type, uint8 item_to_exchange_item_type,,) = common_crafting.items(item_to_exchange);
    uint item_to_exchange_cost = common_crafting.get_item_cost(item_to_exchange_base_type, item_to_exchange_item_type);
    require(item_to_exchange_cost >= (3 * tools_cost), "! >= 3*tools_cost");

    common_crafting.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), item_to_exchange);
    _safeMint(msg.sender, next_token);
    items[next_token] = Item(base_type, tools_id, uint32(block.timestamp), summoner);
    emit Exchanged(msg.sender, next_token, summoner, base_type, tools_id, item_to_exchange);

    next_token++;
  }

  // TODO: tokenURI

}