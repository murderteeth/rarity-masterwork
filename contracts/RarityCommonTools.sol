//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./core/interfaces/IRarity.sol";
import "./core/interfaces/ICrafting.sol";

contract RarityCommonTools is ERC721Enumerable {
  uint8 public constant baseType = 4;
  uint8 public constant itemType = 1;
  uint public constant cost = 5e18;
  uint public nextToken = 1;

  IRarity rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  ICrafting commonCrafting = ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

  event Exchanged(address indexed owner, uint tokenId, uint summoner, uint8 baseType, uint8 itemType, uint exchangedItem);

  constructor() ERC721("Rarity Common Tools", "RC(I) Tools") {}

  struct Item {
    uint8 base_type;
    uint8 item_type;
    uint32 crafted;
    uint crafter;
  }

  mapping(uint => Item) public items;

  function craftBonus(uint token) public view returns (uint) {
    require(authorizeToken(token), "!authorizeToken");
    return 0;
  }

  function exchange(uint summoner, uint itemToExchange) external {
    require(authorizeSummoner(summoner), "!authorizeSummoner");

    (uint8 itemToExchangeBaseType, uint8 itemToExchangeItemType,,) = commonCrafting.items(itemToExchange);
    uint itemToExchangeCost = commonCrafting.get_item_cost(itemToExchangeBaseType, itemToExchangeItemType);
    require(itemToExchangeCost >= (3 * cost), "! >= 3*cost");

    commonCrafting.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), itemToExchange);
    _safeMint(msg.sender, nextToken);
    items[nextToken] = Item(baseType, baseType, uint32(block.timestamp), summoner);
    emit Exchanged(msg.sender, nextToken, summoner, baseType, itemType, itemToExchange);

    nextToken++;
  }

  // TODO: tokenURI

  function authorizeToken(uint token) internal view returns (bool) {
    address owner = ownerOf(token);
    return owner == msg.sender || getApproved(token) == msg.sender || isApprovedForAll(owner, msg.sender);
  }

  function authorizeSummoner(uint summoner) internal view returns (bool) {
    address owner = rarity.ownerOf(summoner);
    return owner == msg.sender || rarity.getApproved(summoner) == msg.sender || rarity.isApprovedForAll(owner, msg.sender);
  }

}