//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../interfaces/core/IRarityCommonCrafting.sol";
import "../library/Codex.sol";
import "../library/Effects.sol";
import "../library/ForSummoners.sol";

contract rarity_crafting_tools is ERC721Enumerable, IEffects, ForSummoners {
  uint8 public constant base_type = 4; //tools
  uint public next_token = 1;

  IRarityCommonCrafting public constant COMMON_CRAFTING = IRarityCommonCrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
  ICodexTools TOOLS_CODEX = ICodexTools(0x0000000000000000000000000000000000000000);

  event Exchanged(address indexed owner, uint token_id, uint summoner, uint8 base_type, uint8 item_type, uint exchanged_item);

  constructor() ERC721("Rarity Common Tools", "RC(I) Tools") {}

  struct Item {
    uint8 base_type;
    uint8 item_type;
    uint64 crafted;
    uint crafter;
  }

  mapping(uint => Item) public items;

  function attack_bonus(uint token) override external pure returns (int8 result) { token; result = 0; }

  function skill_bonus(uint token, uint8 skill) override external view returns (int8 result) {
    Item memory item = items[token];
    ITools.Tools memory tools = TOOLS_CODEX.item_by_id(item.item_type);
    result = tools.skill_bonus[skill];
  }

  function exchange(uint summoner, uint item_to_exchange) external approvedForSummoner(summoner) {
    ITools.Tools memory tools = TOOLS_CODEX.item_by_id(2);

    (uint8 item_to_exchange_base_type, uint8 item_to_exchange_item_type,,) = COMMON_CRAFTING.items(item_to_exchange);
    uint item_to_exchange_cost = COMMON_CRAFTING.get_item_cost(item_to_exchange_base_type, item_to_exchange_item_type);
    require(item_to_exchange_cost >= (3 * tools.cost), "! >= 3*cost");

    COMMON_CRAFTING.safeTransferFrom(_msgSender(), address(0x000000000000000000000000000000000000dEaD), item_to_exchange);
    _safeMint(_msgSender(), next_token);
    items[next_token] = Item(base_type, tools.id, uint64(block.timestamp), summoner);
    emit Exchanged(_msgSender(), next_token, summoner, base_type, tools.id, item_to_exchange);

    next_token += 1;
  }

  // TODO: tokenURI

}