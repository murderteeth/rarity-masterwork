//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./core/interfaces/ICrafting.sol";
import "./utils/RarityHelpers.sol";

contract RarityCommonTools is ERC721Enumerable {
    uint8 public constant baseType = 4;
    uint8 public constant itemType = 1;
    uint256 public constant cost = 5e18;
    uint256 public nextToken = 1;

    ICrafting commonCrafting =
        ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);

    event Exchanged(
        address indexed owner,
        uint256 tokenId,
        uint256 summoner,
        uint8 baseType,
        uint8 itemType,
        uint256 exchangedItem
    );

    constructor() ERC721("Rarity Common Tools", "RC(I) Tools") {}

    struct Item {
        uint8 base_type;
        uint8 item_type;
        uint32 crafted;
        uint256 crafter;
    }

    mapping(uint256 => Item) public items;

    function exchange(uint256 summoner, uint256 itemToExchange)
        external
        approvedForSummoner(summoner)
    {
        (
            uint8 itemToExchangeBaseType,
            uint8 itemToExchangeItemType,
            ,

        ) = commonCrafting.items(itemToExchange);
        uint256 itemToExchangeCost = commonCrafting.get_item_cost(
            itemToExchangeBaseType,
            itemToExchangeItemType
        );
        require(itemToExchangeCost >= (3 * cost), "! >= 3*cost");

        commonCrafting.safeTransferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            itemToExchange
        );
        _safeMint(msg.sender, nextToken);
        items[nextToken] = Item(
            baseType,
            baseType,
            uint32(block.timestamp),
            summoner
        );
        emit Exchanged(
            msg.sender,
            nextToken,
            summoner,
            baseType,
            itemType,
            itemToExchange
        );

        nextToken++;
    }

    // TODO: tokenURI

    modifier approvedForSummoner(uint256 summonerId) {
        if (RarityHelpers._isApprovedOrOwnerOfSummoner(summonerId)) {
            revert("!approved");
        } else {
            _;
        }
    }
}
