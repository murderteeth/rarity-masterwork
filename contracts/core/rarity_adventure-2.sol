//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/core/IRarity.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Attributes.sol";
import "../library/Codex.sol";
import "../library/Combat.sol";
import "../library/Crafting.sol";
import "../library/Effects.sol";
import "../library/Monster.sol";
import "../library/Proficiency.sol";
import "../library/Random.sol";
import "../library/Roll.sol";
import "../library/StringUtil.sol";
import "../library/Summoner.sol";

contract rarity_adventure_2 is ERC721Enumerable, IERC721Receiver, ForSummoners, ForItems {
  uint public next_token = 1;
  uint public next_monster = 1;

  // MONSTERS
  // 1 kobold (CR 1/4)
  // 3 goblin (CR 1/3)
  // 4 gnoll (CR 1)
  // 6 black bear (CR 2)
  // 7 ogre (CR 3)
  // 8 dire boar (CR 4)
  // 9 dire wolverine (CR 4)
  // 10 troll (CR 5)
  // 11 ettin (CR 6)

  uint8[9] public MONSTERS = [1, 3, 4, 6, 7, 11, 8, 9, 10];
  uint8[6] public MONSTER_FOR_LEVEL = [4, 6, 6, 7, 7, 11];
  uint8[9] public MONSTER_BONUS_INDEX_FOR_LEVEL = [2, 3, 3, 4, 4, 5, 6, 7, 8];

  uint8 public constant EQUIPMENT_SLOTS = 3;
  uint8 public constant EQUIPMENT_TYPE_WEAPON = 0;
  uint8 public constant EQUIPMENT_TYPE_ARMOR = 1;
  uint8 public constant EQUIPMENT_TYPE_SHIELD = 2;

  uint8 public constant SEARCH_DC = 20;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

  address[2] public ITEM_WHITELIST;

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event RollInitiative(address indexed owner, uint indexed token, uint8 roll, int8 score);
  event Attack(address indexed owner, uint indexed token, uint attacker, uint defender, uint8 round, bool hit, uint8 roll, int8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type);
  event Dying(address indexed owner, uint indexed token, uint8 round, uint combatant);
  event SearchCheck(address indexed owner, uint indexed token, uint8 roll, int8 score);

  struct Adventure {
    bool dungeon_entered;
    bool combat_ended;
    bool search_check_rolled;
    bool search_check_succeeded;
    bool search_check_critical;
    uint8 monster_count;
    uint8 monsters_defeated;
    uint8 combat_round;
    uint64 started;
    uint64 ended;
    uint summoner;
  }

  mapping(uint => Adventure) public adventures;
  mapping(uint => uint) public latest_adventures;
  mapping(uint => uint8) public monster_spawn;
  mapping(uint => Combat.EquipmentSlot[EQUIPMENT_SLOTS]) public equipment_slots;
  mapping(address => mapping(uint => uint)) public equipment_index;
  mapping(uint => Combat.Combatant[]) public turn_orders;
  mapping(uint => uint) public summoners_turns;
  mapping(uint => uint) public current_turns;
  mapping(uint => uint) public attack_counters;

  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator; from; tokenId; data; // lint silencio!
    return this.onERC721Received.selector;
  }

  function set_item_whitelist(address commonWrapper, address masterwork) public {
    require(ITEM_WHITELIST[0] == address(0), "whitelist already set");
    require(commonWrapper != address(0), "commonWrapper == address(0)");
    require(masterwork != address(0), "masterwork == address(0)");
    ITEM_WHITELIST[0] = commonWrapper;
    ITEM_WHITELIST[1] = masterwork;

    ICrafting common = ICrafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
    common.setApprovalForAll(commonWrapper, true);
  }

  function time_to_next_adventure(uint summoner) public view returns (uint time) {
    uint latest_adventure_token = latest_adventures[summoner];
    if(latest_adventure_token != 0) {
      Adventure memory latest_adventure = adventures[latest_adventure_token];
      uint next_adventure = latest_adventure.started + 1 days;
      if(next_adventure > block.timestamp) {
        time = next_adventure - block.timestamp;
      }
    }
  }

  function start(uint summoner) public approvedForSummoner(summoner) {
    uint latest_adventure_token = latest_adventures[summoner];
    if(latest_adventure_token != 0) {
      Adventure memory latest_adventure = adventures[latest_adventure_token];
      require(latest_adventure.ended > 0, "!latest_adventure.ended");
      require(block.timestamp >= (latest_adventure.started + 1 days), "!1day");
    }

    require(RARITY.level(summoner) > 0, "level == 0");

    adventures[next_token].summoner = summoner;
    adventures[next_token].started = uint64(block.timestamp);
    latest_adventures[summoner] = next_token;
    RARITY.safeTransferFrom(msg.sender, address(this), summoner);
    RARITY.approve(msg.sender, summoner);
    _safeMint(msg.sender, next_token);
    next_token += 1;
  }

  function equip(
    uint token,
    uint8 equipment_type,
    uint item,
    address item_contract
    ) public 
    approvedForAdventure(token)
    approvedForItem(item, item_contract)
  {
    require_outside_dungeon(adventures[token]);
    require(equipment_type < 3, "!equipment_type");
    require(whitelisted(item_contract), "!whitelisted");

    if(item_contract != address(0)) {
      (uint8 base_type, uint8 item_type,,) = ICrafting(item_contract).items(item);
      if(equipment_type == EQUIPMENT_TYPE_WEAPON) {
        require(base_type == 3, "!weapon");
        IWeapon.Weapon memory weapon = IWeapon(item_contract).get_weapon(item_type);
        if(weapon.encumbrance == 5) revert("ranged weapon");
        if(weapon.encumbrance == 4) {
          Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];
          if(shield_slot.item_contract != address(0)) revert("shield equipped");
        }
      } else if(equipment_type == EQUIPMENT_TYPE_ARMOR) {
        require(base_type == 2 && item_type < 13, "!armor");
      } else if(equipment_type == EQUIPMENT_TYPE_SHIELD) {
        require(base_type == 2 && item_type > 12, "!shield");
        Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
        if(weapon_slot.item_contract != address(0)) {
          (, uint8 equipped_type,,) = ICrafting(weapon_slot.item_contract).items(weapon_slot.item);
          IWeapon.Weapon memory equipped_weapon = IWeapon(item_contract).get_weapon(equipped_type);
          if(equipped_weapon.encumbrance == 4) revert("two-handed weapon equipped");
        }
      }
    }

    Combat.EquipmentSlot storage slot = equipment_slots[token][equipment_type];
    if(item_contract != slot.item_contract || item != slot.item) {
      address current_item_contract = slot.item_contract;
      uint current_item = slot.item;

      if(item_contract != address(0)) {
        require(equipment_index[item_contract][item] == 0, "!item available");
        ICrafting(item_contract).safeTransferFrom(msg.sender, address(this), item);
        ICrafting(item_contract).approve(msg.sender, item);
        slot.item = item;
        slot.item_contract = item_contract;
        equipment_index[item_contract][item] = token;
      } else {
        delete slot.item;
        delete slot.item_contract;
      }

      if(current_item_contract != address(0)) {
        delete equipment_index[current_item_contract][current_item];
        ICrafting(current_item_contract).safeTransferFrom(address(this), msg.sender, current_item);
      }
    }
  }

  function enter_dungeon(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require_outside_dungeon(adventure);

    adventure.dungeon_entered = true;
    (uint8 monster_count, uint8[3] memory monsters) = roll_monsters(
      token, 
      RARITY.level(adventure.summoner)
    );
    adventure.monster_count = monster_count;

    uint8 number_of_combatants = adventure.monster_count + 1;
    Combat.Combatant[] memory combatants = new Combat.Combatant[](number_of_combatants);
    combatants[0] = summoner_combatant(token, adventure.summoner);
    for(uint i = 0; i < adventure.monster_count; i++) {
      combatants[i + 1] = monster_combatant(Monster.monster_by_id(monsters[i]));
    }

    Combat.order_by_initiative(combatants);
    Combat.Combatant[] storage turn_order = turn_orders[token];
    for(uint i = 0; i < number_of_combatants; i++) {
      turn_order.push(combatants[i]);
    }

    adventure.combat_round = 1;
    set_summoners_turn(token, combatants);
    combat_loop_until_summoners_next_turn(token);
  }

  function next_able_monster(uint token) public view returns(uint monsters_turn_order) {
    Combat.Combatant[] storage turn_order = turn_orders[token];
    uint turn_count = turn_order.length;
    for(uint i = 0; i < turn_count; i++) {
      Combat.Combatant storage combatant = turn_order[i];
      if(combatant.origin == address(this) && combatant.hit_points > -1) return i;
    }
    revert("no able monster");
  }

  function attack(uint token, uint target) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require_en_combat(adventure);

    uint attack_counter = attack_counters[token];

    uint summoners_turn = summoners_turns[token];
    uint current_turn = current_turns[token];
    require(current_turn == summoners_turn, "!summoners_turn");

    Combat.Combatant[] storage turn_order = turn_orders[token];
    Combat.Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;
    require(target < turn_count, "target out of bounds");

    Combat.Combatant storage monster = turn_order[target];
    require(monster.origin == address(this), "monster.origin != address(this)");
    require(monster.hit_points > -1, "monster.hit_points < 0");

    attack_combatant(token, summoners_turn, summoner, target, monster, attack_counter, adventure.combat_round);

    if(monster.hit_points < 0) {
      adventure.monsters_defeated += 1;
      emit Dying(msg.sender, token, adventure.combat_round, target);
    }

    if(adventure.monsters_defeated == adventure.monster_count) {
      adventure.combat_ended = true;
    } else {
      if(attack_counter < 3 && Combat.has_attack(summoner.attacks, attack_counter + 1)) {
        attack_counters[token] = attack_counter + 1;
      } else {
        attack_counters[token] = 0;
        current_turn = next_turn(adventure, turn_count, current_turn);  
        current_turns[token] = current_turn;  
        combat_loop_until_summoners_next_turn(token);
      }
    }
  }

  function flee(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require_en_combat(adventure);
    adventure.combat_ended = true;
  }

  function search(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require(!adventure.search_check_rolled, "search_check_rolled");
    require_victory(adventure);
    require_not_ended(adventure);

    (uint8 roll, int8 score) = Roll.search(adventure.summoner);

    adventure.search_check_rolled = true;
    adventure.search_check_succeeded = roll == 20 || score >= int8(SEARCH_DC);
    adventure.search_check_critical = roll == 20;
    emit SearchCheck(msg.sender, token, roll, score);
  }

  function end(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require_not_ended(adventure);
    adventure.ended = uint64(block.timestamp);

    RARITY.safeTransferFrom(address(this), msg.sender, adventure.summoner);

    Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    if(weapon_slot.item_contract != address(0)) {
      delete equipment_index[weapon_slot.item_contract][weapon_slot.item];
      ICrafting(weapon_slot.item_contract).safeTransferFrom(address(this), msg.sender, weapon_slot.item);
    }

    Combat.EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    if(armor_slot.item_contract != address(0)) {
      delete equipment_index[armor_slot.item_contract][armor_slot.item];
      ICrafting(armor_slot.item_contract).safeTransferFrom(address(this), msg.sender, armor_slot.item);
    }

    Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];
    if(shield_slot.item_contract != address(0)) {
      delete equipment_index[shield_slot.item_contract][shield_slot.item];
      ICrafting(shield_slot.item_contract).safeTransferFrom(address(this), msg.sender, shield_slot.item);
    }
  }

  function whitelisted(address contract_address) internal view returns (bool) {
    return contract_address == address(0)
    || contract_address == ITEM_WHITELIST[0]
    || contract_address == ITEM_WHITELIST[1];
  }

  function roll_monsters(
    uint token, 
    uint level
  ) public view returns (
    uint8 monster_count, 
    uint8[3] memory monsters
  ) {
    monsters[monster_count] = MONSTER_FOR_LEVEL[level > 6 ? 5 : level - 1];
    monster_count++;

    if(Random.dn(12586470658909511785, token, 100) > 50) {
      uint8 bonus_index = MONSTER_BONUS_INDEX_FOR_LEVEL[level > 5 ? 4 : level - 1];
      monsters[monster_count] = MONSTERS[Random.dn(15608573760256557610, token, bonus_index + 1) - 1];
      monster_count++;
    }

    if(level > 6 && Random.dn(1593506169583491991, token, 100) > 50) {
      uint8 bonus_index = MONSTER_BONUS_INDEX_FOR_LEVEL[level > 9 ? 8 : level - 1];
      monsters[monster_count] = MONSTERS[Random.dn(15241373560133191304, token, bonus_index + 1) - 1];
      monster_count++;
    }
  }

  function summoner_combatant(uint token, uint summoner) internal returns(Combat.Combatant memory combatant) {
    (uint8 initiative_roll, int8 initiative_score) = Roll.initiative(summoner);
    emit RollInitiative(msg.sender, token, initiative_roll, initiative_score);

    Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    Combat.EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];

    combatant.origin = address(RARITY);
    combatant.token = summoner;
    combatant.initiative_roll = initiative_roll;
    combatant.initiative_score = initiative_score;
    combatant.hit_points = int16(uint16(Summoner.hit_points(summoner)));
    combatant.armor_class = Summoner.armor_class(summoner, armor_slot, shield_slot);
    combatant.attacks = Summoner.attacks(summoner, weapon_slot, armor_slot, shield_slot);
  }

  function monster_combatant(Monster.MonsterCodex memory monster_codex) internal returns(Combat.Combatant memory combatant) {
    monster_spawn[next_monster] = monster_codex.id;

    (uint8 initiative_roll, int8 initiative_score) = Roll.initiative(
      next_monster, 
      Attributes.compute_modifier(monster_codex.abilities[1]), 
      monster_codex.initiative_bonus
    );

    combatant.origin = address(this);
    combatant.token = next_monster;
    combatant.initiative_roll = initiative_roll;
    combatant.initiative_score = initiative_score;
    combatant.hit_points = Monster.hit_points(monster_codex, next_monster);
    combatant.armor_class = monster_codex.armor_class;
    combatant.attacks = monster_codex.attacks;

    next_monster += 1;
  }

  function set_summoners_turn(uint token, Combat.Combatant[] memory combatants) internal {
    uint length = combatants.length;
    for(uint i = 0; i < length; i++) {
      if(combatants[i].origin == address(RARITY)) {
        summoners_turns[token] = i;
        break;
      }
    }
  }

  function combat_loop_until_summoners_next_turn(uint token) internal {
    Adventure storage adventure = adventures[token];
    uint summoners_turn = summoners_turns[token];
    uint current_turn = current_turns[token];
    if(current_turn == summoners_turn) return;

    Combat.Combatant[] storage turn_order = turn_orders[token];
    Combat.Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;

    do {
      Combat.Combatant memory monster = turn_order[current_turn];
      uint attack_counter = attack_counters[token];
      if(monster.hit_points > -1) {
        attack_combatant(token, current_turn, monster, summoners_turn, summoner, attack_counter, adventure.combat_round);
        if(attack_counter < 3 && Combat.has_attack(monster.attacks, attack_counter + 1)) {
          attack_counters[token] = attack_counter + 1;
        } else {
          attack_counters[token] = 0;
          current_turn = next_turn(adventure, turn_count, current_turn);
        }
      } else {
        current_turn = next_turn(adventure, turn_count, current_turn);
      }
    } while(current_turn != summoners_turn && (summoner.hit_points > -1));

    current_turns[token] = current_turn;
    if(summoner.hit_points < 0) {
      adventure.combat_ended = true;
      emit Dying(msg.sender, token, adventure.combat_round, summoners_turn);
    }
  }

  function next_turn(Adventure storage adventure, uint turn_count, uint current_turn) internal returns (uint) {
    if(current_turn >= (turn_count - 1)) {
      adventure.combat_round += 1;
      return 0;
    } else {
      return current_turn + 1;
    }
  }

  function attack_combatant(uint token, uint attacker_index, Combat.Combatant memory attacker, uint defender_index, Combat.Combatant storage defender, uint attack_number, uint8 round) internal {
    (bool hit, uint8 roll, int8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type) 
    = Combat.attack_combatant(attacker, defender, attack_number);
    emit Attack(msg.sender, token, attacker_index, defender_index, round, hit, roll, score, critical_confirmation, damage, damage_type);
  }

  function outside_dungeon(Adventure memory adventure) public pure returns (bool) {
    return !adventure.dungeon_entered 
    && adventure.ended == 0;
  }

  function require_outside_dungeon(Adventure memory adventure) public pure {
    require(outside_dungeon(adventure), "!outside_dungeon");
  }

  function is_outside_dungeon(uint token) external view returns (bool) {
    return outside_dungeon(adventures[token]);
  }

  function en_combat(Adventure memory adventure) public pure returns (bool) {
    return adventure.dungeon_entered 
    && !adventure.combat_ended
    && adventure.ended == 0;
  }

  function require_en_combat(Adventure memory adventure) public pure {
    require(en_combat(adventure), "!en_combat");
  }

  function is_en_combat(uint token) external view returns (bool) {
    return en_combat(adventures[token]);
  }

  function combat_over(Adventure memory adventure) public pure returns (bool) {
    return adventure.dungeon_entered 
    && adventure.combat_ended
    && adventure.ended == 0;
  }

  function require_combat_over(Adventure memory adventure) public pure {
    require(combat_over(adventure), "!combat_over");
  }

  function is_combat_over(uint token) external view returns (bool) {
    return combat_over(adventures[token]);
  }

  function ended(Adventure memory adventure) public pure returns (bool) {
    return adventure.ended > 0;
  }

  function require_not_ended(Adventure memory adventure) public pure {
    require(!ended(adventure), "ended");
  }

  function require_ended(Adventure memory adventure) public pure {
    require(ended(adventure), "!ended");
  }

  function is_ended(uint token) external view returns (bool) {
    return ended(adventures[token]);
  }

  function victory(Adventure memory adventure) public pure returns (bool) {
    return adventure.monster_count == adventure.monsters_defeated;
  }

  function require_victory(Adventure memory adventure) public pure {
    require(victory(adventure), "!victory");
  }

  function is_victory(uint token) external view returns (bool) {
    return victory(adventures[token]);
  }

  function count_loot(Adventure memory adventure, Combat.Combatant[] memory turn_order) public view returns (uint) {
    if(!victory(adventure)) return 0;

    uint reward = 0;
    uint8 turn_count = adventure.monster_count + 1;
    for(uint i = 0; i < turn_count; i++) {
      Combat.Combatant memory combatant = turn_order[i];
      if(combatant.origin == address(this)) {
        reward += Monster.monster_by_id(monster_spawn[combatant.token]).challenge_rating;
      }
    }

    if(adventure.search_check_succeeded) {
      if(adventure.search_check_critical) {
        reward = 6 * reward / 5;
      } else {
        reward = 23 * reward / 20;
      }
    }

    return reward * 1e18 / 10;
  }

  function count_loot(uint token) public view returns (uint) {
    return count_loot(adventures[token], turn_orders[token]);
  }

  function fled(uint token, Adventure memory adventure, Combat.Combatant[] memory turn_order) public view returns (bool) {
    return combat_over(adventure) 
      && adventure.monster_count > adventure.monsters_defeated
      && turn_order[summoners_turns[token]].hit_points > -1;
  }

  function was_fled(uint token) external view returns (bool) {
    return fled(token, adventures[token], turn_orders[token]);
  }

  function is_proficient_with_weapon(uint summoner, uint8 weapon_type, address weapon_contract) public view returns (bool) {
    return Proficiency.is_proficient_with_weapon(summoner, IWeapon(weapon_contract).get_weapon(weapon_type).proficiency, weapon_type);
  }

  function is_proficient_with_armor(uint summoner, uint8 armor_type, address armor_contract) public view returns (bool) {
    return Proficiency.is_proficient_with_armor(summoner, IArmor(armor_contract).get_armor(armor_type).proficiency, armor_type);
  }

  function preview(
    uint summoner, 
    uint weapon, 
    address weapon_contract, 
    uint armor, 
    address armor_contract, 
    uint shield, 
    address shield_contract
  ) public view returns (Combat.Combatant memory result) {
    Combat.EquipmentSlot memory weapon_slot = Combat.EquipmentSlot(weapon_contract, weapon);
    Combat.EquipmentSlot memory armor_slot = Combat.EquipmentSlot(armor_contract, armor);
    Combat.EquipmentSlot memory shield_slot = Combat.EquipmentSlot(shield_contract, shield);
    result.token = summoner;
    result.origin = address(RARITY);
    result.hit_points = int16(uint16(Summoner.hit_points(summoner)));
    result.armor_class = Summoner.armor_class(summoner, armor_slot, shield_slot);
    result.attacks = Summoner.attacks(summoner, weapon_slot, armor_slot, shield_slot);
  }

  function isApprovedOrOwnerOfAdventure(uint token) public view returns (bool) {
    if(getApproved(token) == msg.sender) return true;
    address owner = ownerOf(token);
    return owner == msg.sender || isApprovedForAll(owner, msg.sender);
  }

  modifier approvedForAdventure(uint token) {
    if (isApprovedOrOwnerOfAdventure(token)) {
      _;
    } else {
      revert("!approvedForAdventure");
    }
  }

  function _transfer(address from, address to, uint token) internal override {
    Adventure memory adventure = adventures[token];
    RARITY.approve(to, adventure.summoner);

    Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    if(weapon_slot.item_contract != address(0)) {
      ICrafting(weapon_slot.item_contract).approve(to, weapon_slot.item);
    }

    Combat.EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    if(armor_slot.item_contract != address(0)) {
      ICrafting(armor_slot.item_contract).approve(to, armor_slot.item);
    }

    Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];
    if(shield_slot.item_contract != address(0)) {
      ICrafting(shield_slot.item_contract).approve(to, shield_slot.item);
    }

    super._transfer(from, to, token);
  }

  function tokenURI(uint token) public view virtual override returns (string memory) {
    Adventure memory adventure = adventures[token];
    Combat.Combatant[] memory turn_order = turn_orders[token];

    uint y = 0;
    string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 340 340" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'status ', status_string(token, adventure, turn_order), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'summoner ', summoner_string(token, adventure, turn_order), '</text>'));

    y += 20; (string memory loadout_fragment, uint y_after_loadout) = loadout_svg_fragment(token, y);
    svg = string(abi.encodePacked(svg, loadout_fragment));

    y = y_after_loadout + 20; (string memory monster_fragment, uint y_after_monsters) = monsters_svg_fragment(token, y, adventure, turn_order);
    svg = string(abi.encodePacked(svg, monster_fragment));

    y = y_after_monsters; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'loot ', loot_string(token, adventure, turn_order), '</text>'));
    y += 20; svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'started ', StringUtil.toString(adventure.started), '</text>'));
    y += 20; if(adventure.ended > 0) svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'ended ', StringUtil.toString(adventure.ended), '</text>'));
    else svg = string(abi.encodePacked(svg, '<text x="10" y="', StringUtil.toString(y), '" class="base">', 'ended --</text>'));
    svg = string(abi.encodePacked(svg, '</svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "adventure #', StringUtil.toString(token), '", "description": "Rarity Adventure 2: Monsters in the Barn. Fight monsters, claim salvage, craft Rarity masterwork items.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function status_string(uint token, Adventure memory adventure, Combat.Combatant[] memory turn_order) internal view returns (string memory result) {
    if(outside_dungeon(adventure)) result = "Outside the dungeon";
    else if(en_combat(adventure)) result = string(abi.encodePacked("Combat in Round", " ", StringUtil.toString(adventure.combat_round)));
    else if(combat_over(adventure)) result = "Looting";
    else if(ended(adventure)) {
      if(victory(adventure)) {
        result = string(abi.encodePacked("Victory! during Round", " ", StringUtil.toString(adventure.combat_round)));
      } else {
        if(fled(token, adventure, turn_order)) {
          result = string(abi.encodePacked("Fled during Round", " ", StringUtil.toString(adventure.combat_round)));
        } else {
          result = string(abi.encodePacked("Defeat during Round", " ", StringUtil.toString(adventure.combat_round)));
        }
      }
    }
  }

  function summoner_string(uint token, Adventure memory adventure, Combat.Combatant[] memory turn_order) internal view returns (string memory result) {
    result = StringUtil.toString(adventure.summoner);
    if(turn_order.length > 0) {
      result = string(abi.encodePacked(
        result, 
        " (", StringUtil.toString(turn_order[summoners_turns[token]].hit_points), "hp)"
      ));
    }
  }

  function monsters_svg_fragment(uint token, uint y, Adventure memory adventure, Combat.Combatant[] memory turn_order) internal view returns (string memory result, uint new_y) {
    uint turn_count = turn_order.length;
    uint summoners_turn = summoners_turns[token];

    result = string(abi.encodePacked('<text x="10" y="', StringUtil.toString(y), '" class="base">monsters</text>'));
    y += 20;

    if(adventure.monster_count == 0) {
      result = string(abi.encodePacked(
        result, '<text x="20" y="', StringUtil.toString(y), '" class="base">--</text>'
      ));
    } else {
      for(uint i = 0; i < turn_count; i++) {
        if(i != summoners_turn) {
          result = string(abi.encodePacked(
            result, '<text x="20" y="', StringUtil.toString(y), '" class="base">', 
            Monster.monster_by_id(monster_spawn[turn_order[i].token]).name,
            " (", StringUtil.toString(turn_order[i].hit_points), "hp)", '</text>'
          ));
          y += 20;
        }
      }
    }

    new_y = y;
  }

  function loadout_svg_fragment(uint token, uint y) internal view returns (string memory result, uint new_y) {
    result = string(abi.encodePacked('<text x="10" y="', StringUtil.toString(y), '" class="base">loadout</text>'));
    y += 20;

    Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    Combat.EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];
    if(weapon_slot.item_contract == address(0)) {
      result = string(abi.encodePacked('<text x="20" y="', StringUtil.toString(y), '" class="base">Unarmed</text>'));
      y += 20;
    } else {
      (,uint8 item_type,,) = ICrafting(weapon_slot.item_contract).items(weapon_slot.item);
      result = string(abi.encodePacked(
        result, '<text x="20" y="', StringUtil.toString(y), '" class="base">', 
        IWeapon(weapon_slot.item_contract).get_weapon(item_type).name,
        '</text>'
      ));
      y += 20;
    }

    if(armor_slot.item_contract == address(0) && shield_slot.item_contract == address(0)) {
      result = string(abi.encodePacked('<text x="20" y="', StringUtil.toString(y), '" class="base">Unarmored</text>'));
    } else {
      if(armor_slot.item_contract != address(0)) {
        (,uint8 item_type,,) = ICrafting(armor_slot.item_contract).items(armor_slot.item);
        result = string(abi.encodePacked(
          result, '<text x="20" y="', StringUtil.toString(y), '" class="base">', 
          IArmor(armor_slot.item_contract).get_armor(item_type).name,
          '</text>'
        ));
        y += 20;
      }
      if(shield_slot.item_contract != address(0)) {
        (,uint8 item_type,,) = ICrafting(shield_slot.item_contract).items(shield_slot.item);
        result = string(abi.encodePacked(
          result, '<text x="20" y="', StringUtil.toString(y), '" class="base">', 
          IArmor(shield_slot.item_contract).get_armor(item_type).name,
          '</text>'
        ));
      }
    }

    new_y = y;
  }

  function loot_string(uint token, Adventure memory adventure, Combat.Combatant[] memory turn_order) internal view returns (string memory result) {
    result = "--";
    if(ended(adventure) && victory(adventure)) result = string(abi.encodePacked(StringUtil.toString(count_loot(adventure, turn_order) / 1e18), " Salvage"));
  }

}