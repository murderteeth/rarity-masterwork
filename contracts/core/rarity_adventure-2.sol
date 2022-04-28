//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
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
import "../library/Summoner.sol";

contract rarity_adventure_2 is ERC721Enumerable, IERC721Receiver, ForSummoners, ForItems {
  uint public next_token = 1;
  uint public next_monster = 1;

  uint8[10] public MONSTERS = [
    1,  // kobold (CR 1/4)
    3,  // goblin (CR 1/3)
    4,  // gnoll (CR 1)
    6,  // black bear (CR 2)
    7,  // ogre (CR 3)
    9,  // dire wolverine (CR 4)
    10, // troll (CR 5)
    11, // ettin (CR 6)
    12, // hill giant (CR 7)
    13  // stone giant (CR 8)
  ];

  uint8 public constant MONSTER_LEVEL_OFFSET = 1;

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
    RARITY.safeTransferFrom(_msgSender(), address(this), summoner);
    RARITY.approve(_msgSender(), summoner);
    _safeMint(_msgSender(), next_token);
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
      if(slot.item_contract != address(0)) {
        ICrafting(slot.item_contract).safeTransferFrom(address(this), _msgSender(), slot.item);
        delete equipment_index[slot.item_contract][slot.item];
      }
      if(item_contract != address(0)) {
        require(equipment_index[item_contract][item] == 0, "!item available");
        ICrafting(item_contract).safeTransferFrom(_msgSender(), address(this), item);
        ICrafting(item_contract).approve(_msgSender(), item);
        slot.item = item;
        slot.item_contract = item_contract;
        equipment_index[item_contract][item] = token;
      } else {
        delete slot.item;
        delete slot.item_contract;
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
      emit Dying(_msgSender(), token, adventure.combat_round, target);
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
    adventure.search_check_succeeded = score >= int8(SEARCH_DC);
    adventure.search_check_critical = roll == 20;
    emit SearchCheck(_msgSender(), token, roll, score);
  }

  function end(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require_not_ended(adventure);

    RARITY.safeTransferFrom(address(this), _msgSender(), adventure.summoner);

    Combat.EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    if(weapon_slot.item_contract != address(0)) {
      ICrafting(weapon_slot.item_contract).safeTransferFrom(address(this), _msgSender(), weapon_slot.item);
    }

    Combat.EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    if(armor_slot.item_contract != address(0)) {
      ICrafting(armor_slot.item_contract).safeTransferFrom(address(this), _msgSender(), armor_slot.item);
    }

    Combat.EquipmentSlot memory shield_slot = equipment_slots[token][EQUIPMENT_TYPE_SHIELD];
    if(shield_slot.item_contract != address(0)) {
      ICrafting(shield_slot.item_contract).safeTransferFrom(address(this), _msgSender(), shield_slot.item);
    }

    adventure.ended = uint64(block.timestamp);
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
    uint level_or_max = level > 8 ? 8 : level;

    monsters[monster_count] = MONSTERS[MONSTER_LEVEL_OFFSET + level_or_max];
    monster_count++;

    if(Random.dn(12586470658909511785, token, 100) > 50) {
      monsters[monster_count] = MONSTERS[Random.dn(15608573760256557610, token, uint8(MONSTER_LEVEL_OFFSET + level_or_max)) - 1];
      monster_count++;
    }

    if(level_or_max > 3 && Random.dn(1593506169583491991, token, 100) > 50) {
      monsters[monster_count] = MONSTERS[Random.dn(9249786475706550225, token, uint8(MONSTER_LEVEL_OFFSET + level_or_max)) - 1];
      monster_count++;
    }
  }

  function summoner_combatant(uint token, uint summoner) internal returns(Combat.Combatant memory combatant) {
    (uint8 initiative_roll, int8 initiative_score) = Roll.initiative(summoner);
    emit RollInitiative(_msgSender(), token, initiative_roll, initiative_score);

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
      emit Dying(_msgSender(), token, adventure.combat_round, summoners_turn);
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
    emit Attack(_msgSender(), token, attacker_index, defender_index, round, hit, roll, score, critical_confirmation, damage, damage_type);
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
    if(getApproved(token) == _msgSender()) return true;
    address owner = ownerOf(token);
    return owner == _msgSender() || isApprovedForAll(owner, _msgSender());
  }

  modifier approvedForAdventure(uint token) {
    if (isApprovedOrOwnerOfAdventure(token)) {
      _;
    } else {
      revert("!approvedForAdventure");
    }
  }

  // TODO: tokenURI
}