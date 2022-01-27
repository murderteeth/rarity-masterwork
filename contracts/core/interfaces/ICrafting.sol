// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity 0.8.7;

interface ICrafting {
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event Crafted(
        address indexed owner,
        uint256 check,
        uint256 summoner,
        uint256 base_type,
        uint256 item_type,
        uint256 gold,
        uint256 craft_i
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function SUMMMONER_ID() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function craft(
        uint256 _summoner,
        uint8 _base_type,
        uint8 _item_type,
        uint256 _crafting_materials
    ) external;

    function craft_skillcheck(uint256 _summoner, uint256 _dc)
        external
        view
        returns (bool crafted, int256 check);

    function getApproved(uint256 tokenId) external view returns (address);

    function get_armor_dc(uint256 _item_id) external pure returns (uint256 dc);

    function get_dc(uint256 _base_type, uint256 _item_id)
        external
        pure
        returns (uint256 dc);

    function get_goods_dc() external pure returns (uint256 dc);

    function get_item_cost(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (uint256 cost);

    function get_token_uri_armor(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_goods(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_weapon(uint256 _item)
        external
        view
        returns (string memory output);

    function get_type(uint256 _type_id)
        external
        pure
        returns (string memory _type);

    function get_weapon_dc(uint256 _item_id) external pure returns (uint256 dc);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isValid(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (bool);

    function items(uint256)
        external
        view
        returns (
            uint8 base_type,
            uint8 item_type,
            uint32 crafted,
            uint256 crafter
        );

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function name() external view returns (string memory);

    function next_item() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function simulate(
        uint256 _summoner,
        uint256 _base_type,
        uint256 _item_type,
        uint256 _crafting_materials
    )
        external
        view
        returns (
            bool crafted,
            int256 check,
            uint256 cost,
            uint256 dc
        );

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _item) external view returns (string memory uri);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"check","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"base_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"item_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gold","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"craft_i","type":"uint256"}],"name":"Crafted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"SUMMMONER_ID","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8","name":"_base_type","type":"uint8"},{"internalType":"uint8","name":"_item_type","type":"uint8"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"craft","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_dc","type":"uint256"}],"name":"craft_skillcheck","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_armor_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"get_goods_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"get_item_cost","outputs":[{"internalType":"uint256","name":"cost","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_armor","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_goods","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_weapon","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_type_id","type":"uint256"}],"name":"get_type","outputs":[{"internalType":"string","name":"_type","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_weapon_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"isValid","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"items","outputs":[{"internalType":"uint8","name":"base_type","type":"uint8"},{"internalType":"uint8","name":"item_type","type":"uint8"},{"internalType":"uint32","name":"crafted","type":"uint32"},{"internalType":"uint256","name":"crafter","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"next_item","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"simulate","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"uri","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/
