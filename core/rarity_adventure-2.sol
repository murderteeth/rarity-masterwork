//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interfaces/core/IRarity.sol";
import "../interfaces/codex/IRarityCodexCommonWeapons.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Attributes.sol";
import "../library/Combat.sol";
import "../library/Crafting.sol";
import "../library/Monster.sol";
import "../library/Random.sol";
import "../library/Roll.sol";
import "../library/Summoner.sol";

contract rarity_adventure_2 is ERC721Enumerable, IERC721Receiver, ForSummoners, ForItems {
  uint public next_token = 1;
  uint public next_combatant = 1;

  uint8 public constant SKILL_CHECK_DC = 20;
  uint8 public constant EQUIPMENT_SLOTS = 2;
  uint8 public constant EQUIPMENT_TYPE_WEAPON = 0;
  uint8 public constant EQUIPMENT_TYPE_ARMOR = 1;
  uint8[10] public MONSTERS = [1, 3, 4, 6, 7, 9, 10, 11, 12, 13];

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityCodexCommonWeapons constant COMMON_WEAPONS_CODEX = IRarityCodexCommonWeapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event SenseMotive(uint indexed token, uint8 roll, int8 score);
  event RollInitiative(uint indexed token, uint8 roll, int8 score);
  event Attack(uint indexed token, uint attacker, uint defender, uint8 round, bool hit, uint8 roll, uint8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type);
  event Dying(uint indexed token, uint combatant);

  struct Adventure {
    uint summoner;
    uint started;
    uint ended;
    uint8 monster_count;
    uint8 monsters_defeated;
    uint8 combat_round;
    bool dungeon_entered;
    bool combat_ended;
    bool skill_check_rolled;
    bool skill_check_succeeded;
  }

  struct EquipmentSlot {
    uint item;
    address item_contract;
  }

  mapping(uint => Adventure) public adventures;
  mapping(uint => uint) public latest_adventures;
  mapping(uint => EquipmentSlot[EQUIPMENT_SLOTS]) public equipment_slots;
  mapping(address => mapping(uint => uint)) public equipment_index;
  mapping(uint => Combat.Combatant[]) public turn_orders;
  mapping(uint => uint) public summoners_turns;
  mapping(uint => uint) public current_turns;
  mapping(uint => uint) public attack_counters;

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator; from; tokenId; data; // lint silencio!
    return this.onERC721Received.selector;
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

    adventures[next_token].summoner = summoner;
    adventures[next_token].started = block.timestamp;
    latest_adventures[summoner] = next_token;
    RARITY.safeTransferFrom(msg.sender, address(this), summoner);
    _safeMint(_msgSender(), next_token);
    next_token += 1;
  }

  function sense_motive(uint token) public approvedForAdventure(token) onlyDuringActI(token) {
    Adventure storage adventure = adventures[token];
    require(!adventure.skill_check_rolled, "skill_check_rolled");
    Score memory skill_check = Roll.sense_motive(adventure.summoner);
    adventure.skill_check_succeeded = skill_check.score >= int8(SKILL_CHECK_DC);
    adventure.skill_check_rolled = true;
    emit SenseMotive(token, skill_check.roll, skill_check.score);
  }

  function equip(
    uint token,
    uint8 equipment_type,
    uint item,
    address item_contract
    ) public 
    approvedForAdventure(token)
    approvedForItem(item, item_contract)
    onlyDuringActI(token)
  {
    require(equipment_type < 2, "!equipment_type");

    if(item_contract != address(0)) {
      (uint8 base_type, uint8 item_type,,) = ICrafting(item_contract).items(item);
      if(equipment_type == EQUIPMENT_TYPE_WEAPON) {
        require(base_type == 3, "!weapon");
      } else if(equipment_type == EQUIPMENT_TYPE_ARMOR) {
        require(base_type == 2 && item_type < 13, "!armor");
      }
    }

    EquipmentSlot storage slot = equipment_slots[token][equipment_type];
    if(item_contract != slot.item_contract || item != slot.item) {
      if(slot.item_contract != address(0)) {
        ICrafting(slot.item_contract).safeTransferFrom(address(this), msg.sender, slot.item);
        delete equipment_index[slot.item_contract][slot.item];
      }
      if(item_contract != address(0)) {
        require(equipment_index[item_contract][item] == 0, "!item available");
        ICrafting(item_contract).safeTransferFrom(msg.sender, address(this), item);
        slot.item = item;
        slot.item_contract = item_contract;
        equipment_index[item_contract][item] = token;
      } else {
        delete slot.item;
        delete slot.item_contract;
      }
    }
  }

  function roll_monsters(uint token, uint level, bool bonus) public view returns (uint8[3] memory monsters) {
    if(level < 9) {
      monsters[0] = MONSTERS[level + 1];
      monsters[1] = MONSTERS[level];
      monsters[2] = bonus 
      ? level < 2 
        ? MONSTERS[0] 
        : MONSTERS[Random.dn(15608573760256557610, token, uint8(level - 1))]
      : 0;
    } else {
      monsters[0] = MONSTERS[9];
      monsters[1] = MONSTERS[8];
      monsters[2] = 0;
    }
  }

  function enter_dungeon(uint token) public approvedForAdventure(token) onlyDuringActI(token) {
    Adventure storage adventure = adventures[token];
    adventure.dungeon_entered = true;
    adventure.monster_count = adventure.skill_check_succeeded ? 3 : 2;
    uint8[3] memory monsters = roll_monsters(token, RARITY.level(adventure.summoner), adventure.skill_check_succeeded);

    uint8 number_of_combatants = adventure.monster_count + 1;
    Combat.Combatant[] memory combatants = new Combat.Combatant[](number_of_combatants);
    combatants[0] = summoner_combatant(token, adventure.summoner);
    for(uint i = 0; i < adventure.monster_count; i++) {
      combatants[i + 1] = monster_combatant(Monster.monster_by_id(monsters[i]));
    }

    Combat.sort_by_initiative(combatants);
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
      if(!combatant.summoner && combatant.hit_points > -1) return i;
    }
    revert("no able monster");
  }

  function attack(uint token, uint target) public approvedForAdventure(token) onlyDuringActII(token) {
    Adventure storage adventure = adventures[token];
    uint attack_counter = attack_counters[token];

    uint summoners_turn = summoners_turns[token];
    uint current_turn = current_turns[token];
    require(current_turn == summoners_turn, "!summoners_turn");

    Combat.Combatant[] storage turn_order = turn_orders[token];
    Combat.Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;
    require(target < turn_count, "target out of bounds");

    Combat.Combatant storage monster = turn_order[target];
    require(!monster.summoner, "monster.summoner");
    require(monster.hit_points > -1, "monster.hit_points < 0");

    attack_combatant(token, summoner, monster, attack_counter, adventure.combat_round);
    if(monster.hit_points < 0) {
      adventure.monsters_defeated += 1;
      emit Dying(token, monster.token);
    }

    if(adventure.monsters_defeated == adventure.monster_count) {
      adventure.combat_ended = true;
    } else {
      if(attack_counter < 3 && summoner.total_attack_bonus[attack_counter + 1] > 0) {
        attack_counters[token] = attack_counter + 1;
      } else {
        attack_counters[token] = 0;
        current_turn = next_turn(adventure, turn_count, current_turn);  
        current_turns[token] = current_turn;  
        combat_loop_until_summoners_next_turn(token);
      }
    }
  }

  function flee(uint token) public approvedForAdventure(token) onlyDuringActII(token) {
    Adventure storage adventure = adventures[token];
    adventure.combat_ended = true;
  }

  function end(uint token) public approvedForAdventure(token) {
    Adventure storage adventure = adventures[token];
    require(adventure.ended == 0, "adventure.ended != 0");

    RARITY.safeTransferFrom(address(this), msg.sender, adventure.summoner);

    EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    if(weapon_slot.item_contract != address(0)) {
      ICrafting(weapon_slot.item_contract).safeTransferFrom(address(this), msg.sender, weapon_slot.item);
    }

    EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    if(armor_slot.item_contract != address(0)) {
      ICrafting(armor_slot.item_contract).safeTransferFrom(address(this), msg.sender, armor_slot.item);
    }

    adventure.ended = block.timestamp;
  }

  function summoner_combatant(uint token, uint summoner) internal returns(Combat.Combatant memory combatant) {
    EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    codex.weapon memory weapon_codex = get_weapon_codex(weapon_slot);
    int8 base_weapon_modifier = Summoner.base_weapon_modifier(summoner, weapon_codex.encumbrance);

    Score memory initiative = Roll.initiative(summoner);
    emit RollInitiative(token, initiative.roll, initiative.score);

    int8[4] memory total_attack_bonus = Summoner.total_attack_bonus(summoner, base_weapon_modifier);
    int8[16] memory damage;
    for(uint i = 0; i < 4; i++) {
      if(total_attack_bonus[i] > 0) {
        Combat.pack_damage(1, uint8(weapon_codex.damage), base_weapon_modifier, uint8(weapon_codex.damage_type), i, damage);
      } else {
        break;
      }
    }

    combatant = Combat.Combatant({
      summoner: true,
      token: next_combatant,
      host: summoner,
      initiative: initiative,
      hit_points: int16(uint16(Summoner.hit_points(summoner))),
      armor_class: Summoner.armor_class(summoner, armor_slot.item, armor_slot.item_contract),
      critical_modifier: int8(weapon_codex.critical_modifier),
      critical_multiplier: uint8(weapon_codex.critical),
      total_attack_bonus: total_attack_bonus,
      damage: damage
    });

    next_combatant += 1;
  }

  function get_weapon_codex(EquipmentSlot memory weapon_slot) internal view returns (codex.weapon memory) {
    if(weapon_slot.item_contract == address(0)) {
      return unarmed_strike_codex();
    } else {
      (, uint item_type, , ) = ICrafting(weapon_slot.item_contract).items(weapon_slot.item);
      return COMMON_WEAPONS_CODEX.item_by_id(item_type);
    }
  }

  function unarmed_strike_codex() internal pure returns(codex.weapon memory) {
    // _, _, proficiency, _, damage_type, _, damage, critical, critical_modifier, _, _, _
    return codex.weapon(0, 0, 1, 0, 1, 0, 3, 2, 0, 0, "", "");
  }

  function monster_combatant(Monster.MonsterCodex memory monster_codex) internal returns(Combat.Combatant memory combatant) {
    Score memory initiative = Roll.initiative(next_combatant, Attributes.compute_modifier(monster_codex.abilities[1]), monster_codex.initiative_bonus);
    combatant = Combat.Combatant({
      summoner: false,
      token: next_combatant,
      host: monster_codex.id,
      initiative: initiative,
      hit_points: Monster.hit_points(monster_codex, next_combatant),
      armor_class: monster_codex.armor_class,
      total_attack_bonus: monster_codex.total_attack_bonus,
      critical_modifier: monster_codex.critical_modifier,
      critical_multiplier: monster_codex.critical_multiplier,
      damage: monster_codex.damage
    });
    next_combatant += 1;
  }

  function set_summoners_turn(uint token, Combat.Combatant[] memory combatants) internal {
    uint length = combatants.length;
    for(uint i = 0; i < length; i++) {
      if(combatants[i].summoner) {
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
        attack_combatant(token, monster, summoner, attack_counter, adventure.combat_round);
        if(attack_counter < 3 && monster.total_attack_bonus[attack_counter + 1] > 0) {
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
      emit Dying(token, summoner.token);
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

  function attack_combatant(uint token, Combat.Combatant memory attacker, Combat.Combatant storage defender, uint attack_number, uint8 round) internal {
    (bool hit, uint8 roll, uint8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type) 
    = Combat.attack_combatant(attacker, defender, attack_number);
    emit Attack(token, attacker.token, defender.token, round, hit, roll, score, critical_confirmation, damage, damage_type);
  }

  function isApprovedOrOwnerOfAdventure(uint token) public view returns (bool) {
    return getApproved(token) == msg.sender
    || ownerOf(token) == msg.sender
    || isApprovedForAll(ownerOf(token), msg.sender);
  }

  function isActI(uint token) public view returns (bool) {
    Adventure memory adventure = adventures[token];
    return !adventure.dungeon_entered 
    && adventure.ended == 0;
  }

  function isActII(uint token) public view returns (bool) {
    Adventure memory adventure = adventures[token];
    return adventure.dungeon_entered 
    && !adventure.combat_ended
    && adventure.ended == 0;
  }

  modifier approvedForAdventure(uint token) {
    if (isApprovedOrOwnerOfAdventure(token)) {
      _;
    } else {
      revert("!approvedForAdventure");
    }
  }

  modifier onlyDuringActI(uint token) {
    if (isActI(token)) {
      _;
    } else {
      revert("!ActI");
    }    
  }

  modifier onlyDuringActII(uint token) {
    if (isActII(token)) {
      _;
    } else {
      revert("!ActII");
    }
  }

  // TODO: tokenURI
}