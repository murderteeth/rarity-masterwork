//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/core/IRarity.sol";
import "../library/ForSummoners.sol";
import "../library/ForItems.sol";
import "../library/Codex.sol";
import "../library/Combat.sol";
import "../library/Equipment.sol";
import "../library/Monster.sol";
import "../library/Proficiency.sol";
import "../library/Random.sol";
import "../library/Roll.sol";
import "../library/Summoner.sol";
import "./rarity_adventure_2_uri.sol";
import "./rarity_equipment_2.sol";

contract rarity_adventure_2 is ERC721Enumerable, ERC721Holder, ReentrancyGuard, ForSummoners, ForItems {
  uint public next_token = 1;
  uint public next_monster = 1;

  // MONSTERS
  // 1 kobold (CR 1/4)
  // 3 goblin (CR 1/3)
  // 4 gnoll (CR 1)
  // 6 black bear (CR 2)
  // 7 ogre (CR 3)
  // 11 ettin (CR 6)
  // 8 dire boar (CR 4)
  // 9 dire wolverine (CR 4)
  // 10 troll (CR 5)

  uint8[9] public MONSTERS = [1, 3, 4, 6, 7, 11, 8, 9, 10];
  uint8[7] public MONSTERS_BY_LEVEL = [4, 6, 6, 7, 7, 8, 9];
  uint8[9] public MONSTER_BONUS_INDEX_BY_LEVEL = [2, 3, 3, 3, 4, 5, 6, 8, 8];

  uint8 public constant SEARCH_DC = 20;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityEquipment constant EQUIPMENT = IRarityEquipment(0x0000000000000000000000000000000000000011);

  constructor() ERC721("Rarity Adventure (II)", "Adventure (II)") {}

  event RollInitiative(address indexed owner, uint indexed token, uint8 roll, int8 score);
  event Attack(address indexed owner, uint indexed token, uint attacker, uint defender, uint8 round, bool hit, uint8 roll, int8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type);
  event Dying(address indexed owner, uint indexed token, uint8 round, uint combatant);
  event SearchCheck(address indexed owner, uint indexed token, uint8 roll, int8 score);

  mapping(uint => AdventureUri.Adventure) public adventures;
  mapping(uint => uint) public latest_adventures;
  mapping(uint => uint8) public monster_spawn;
  mapping(uint => Combat.Combatant[]) public turn_orders;
  mapping(uint => uint) public summoners_turns;
  mapping(uint => uint) public current_turns;
  mapping(uint => uint) public attack_counters;

  function time_to_next_adventure(uint summoner) public view returns (uint time) {
    uint latest_adventure_token = latest_adventures[summoner];
    if(latest_adventure_token != 0) {
      AdventureUri.Adventure memory latest_adventure = adventures[latest_adventure_token];
      uint next_adventure = latest_adventure.started + 1 days;
      if(next_adventure > block.timestamp) {
        time = next_adventure - block.timestamp;
      }
    }
  }

  function start(uint summoner) public approvedForSummoner(summoner) {
    uint latest_adventure_token = latest_adventures[summoner];
    if(latest_adventure_token != 0) {
      AdventureUri.Adventure memory latest_adventure = adventures[latest_adventure_token];
      require(latest_adventure.ended > 0, "!latest_adventure.ended");
      require(block.timestamp >= (latest_adventure.started + 1 days), "!1day");
    }

    require(RARITY.level(summoner) > 0, "level == 0");

    adventures[next_token].summoner = summoner;
    adventures[next_token].started = uint64(block.timestamp);
    latest_adventures[summoner] = next_token;
    RARITY.safeTransferFrom(msg.sender, address(this), summoner);
    // approve
    // RARITY.approve(msg.sender, summoner);
    EQUIPMENT.snapshot(next_token, summoner);
    _safeMint(msg.sender, next_token);
    next_token += 1;
  }

  function enter_dungeon(uint token) public approvedForAdventure(token) {
    AdventureUri.Adventure storage adventure = adventures[token];
    require(AdventureUri.outside_dungeon(adventure), "!outside_dungeon");

    adventure.dungeon_entered = true;
    (uint8 monster_count, uint8[3] memory monsters) = roll_monsters(
      token, 
      RARITY.level(adventure.summoner)
    );
    adventure.monster_count = monster_count;

    uint8 number_of_combatants = adventure.monster_count + 1;
    Combat.Combatant[] memory combatants = new Combat.Combatant[](number_of_combatants);

    combatants[0] = Summoner.summoner_combatant(adventure.summoner, loadout(token));
    emit RollInitiative(msg.sender, token, combatants[0].initiative_roll, combatants[0].initiative_score);

    for(uint i = 0; i < adventure.monster_count; i++) {
      Monster.MonsterCodex memory monster = Monster.monster_by_id(monsters[i]);
      monster_spawn[next_monster] = monster.id;
      combatants[i + 1] = Monster.monster_combatant(next_monster, address(this), monster);
      next_monster += 1;
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
      if(combatant.mint == address(this) && combatant.hit_points > -1) return i;
    }
    revert("no able monster");
  }

  function attack(uint token, uint target) public approvedForAdventure(token) {
    AdventureUri.Adventure storage adventure = adventures[token];
    require(AdventureUri.en_combat(adventure), "!en_combat");

    uint attack_counter = attack_counters[token];

    uint summoners_turn = summoners_turns[token];
    uint current_turn = current_turns[token];
    require(current_turn == summoners_turn, "!summoners_turn");

    Combat.Combatant[] storage turn_order = turn_orders[token];
    Combat.Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;
    require(target < turn_count, "target out of bounds");

    Combat.Combatant storage monster = turn_order[target];
    require(monster.mint == address(this), "monster.mint != address(this)");
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
    AdventureUri.Adventure storage adventure = adventures[token];
    require(AdventureUri.en_combat(adventure), "!en_combat");
    adventure.combat_ended = true;
  }

  function search(uint token) public approvedForAdventure(token) {
    AdventureUri.Adventure storage adventure = adventures[token];
    require(!adventure.search_check_rolled, "search_check_rolled");
    require(AdventureUri.victory(adventure), "!victory");
    require(!AdventureUri.ended(adventure), "ended");

    (uint8 roll, int8 score) = Roll.search(adventure.summoner);

    adventure.search_check_rolled = true;
    adventure.search_check_succeeded = roll == 20 || score >= int8(SEARCH_DC);
    adventure.search_check_critical = roll == 20;
    emit SearchCheck(msg.sender, token, roll, score);
  }

  function end(uint token) public nonReentrant() approvedForAdventure(token) {
    AdventureUri.Adventure storage adventure = adventures[token];
    require(!AdventureUri.ended(adventure), "ended");
    adventure.ended = uint64(block.timestamp);

    RARITY.safeTransferFrom(address(this), msg.sender, adventure.summoner);
  }

  function roll_monsters(
    uint token, 
    uint level
  ) public view returns (
    uint8 monster_count, 
    uint8[3] memory monsters
  ) {
    monsters[monster_count] = MONSTERS_BY_LEVEL[level > 7 ? 6 : level - 1];
    monster_count++;

    if(Random.dn(12586470658909511785, token, 100) > 50) {
      uint8 bonus_index = MONSTER_BONUS_INDEX_BY_LEVEL[level > 5 ? 4 : level - 1];
      monsters[monster_count] = MONSTERS[Random.dn(15608573760256557610, token, bonus_index + 1) - 1];
      monster_count++;
    }

    if(level > 5 && Random.dn(1593506169583491991, token, 100) > 50) {
      uint8 bonus_index = MONSTER_BONUS_INDEX_BY_LEVEL[level > 9 ? 8 : level - 1];
      monsters[monster_count] = MONSTERS[Random.dn(15241373560133191304, token, bonus_index + 1) - 1];
      monster_count++;
    }
  }

  function monster_combatant(Monster.MonsterCodex memory monster_codex) internal returns(Combat.Combatant memory combatant) {
    monster_spawn[next_monster] = monster_codex.id;
    combatant = Monster.monster_combatant(next_monster, address(this), monster_codex);
    next_monster += 1;
  }

  function set_summoners_turn(uint token, Combat.Combatant[] memory combatants) internal {
    uint length = combatants.length;
    for(uint i = 0; i < length; i++) {
      if(combatants[i].mint == address(RARITY)) {
        summoners_turns[token] = i;
        break;
      }
    }
  }

  function combat_loop_until_summoners_next_turn(uint token) internal {
    AdventureUri.Adventure storage adventure = adventures[token];
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

  function next_turn(AdventureUri.Adventure storage adventure, uint turn_count, uint current_turn) internal returns (uint) {
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

  function is_outside_dungeon(uint token) external view returns (bool) {
    return AdventureUri.outside_dungeon(adventures[token]);
  }

  function is_en_combat(uint token) external view returns (bool) {
    return AdventureUri.en_combat(adventures[token]);
  }

  function is_combat_over(uint token) external view returns (bool) {
    return AdventureUri.combat_over(adventures[token]);
  }

  function is_ended(uint token) external view returns (bool) {
    return AdventureUri.ended(adventures[token]);
  }

  function is_victory(uint token) external view returns (bool) {
    return AdventureUri.victory(adventures[token]);
  }

  function count_loot(uint token) public view returns (uint) {
    AdventureUri.Adventure memory adventure = adventures[token];
    Combat.Combatant[] memory turn_order = turn_orders[token];
    return AdventureUri.count_loot(adventure, turn_order, monster_ids(turn_order, adventure.monster_count));
  }

  function was_fled(uint token) external view returns (bool) {
    return AdventureUri.fled(adventures[token], turn_orders[token]);
  }

  function loadout(uint token) internal view returns (Equipment.Slot[3] memory result) {
    uint summoner = adventures[token].summoner;
    result[0] = EQUIPMENT.snapshots(address(this), token, summoner, 0);
    result[1] = EQUIPMENT.snapshots(address(this), token, summoner, 1);
    result[2] = EQUIPMENT.snapshots(address(this), token, summoner, 2);
  }

  function monster_ids(Combat.Combatant[] memory turn_order, uint monster_count) internal view returns (uint8[] memory result) {
    result = new uint8[](monster_count);
    uint monster_index = 0;
    uint turn_count = turn_order.length;
    for(uint i = 0; i < turn_count; i++) {
      if(turn_order[i].mint == address(this)) {
        result[monster_index++] = monster_spawn[turn_order[i].token];
      }
    }
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
    // AdventureUri.Adventure memory adventure = adventures[token];
    // approve
    // RARITY.approve(to, adventure.summoner);
    super._transfer(from, to, token);
  }

  function tokenURI(uint token) public view virtual override returns (string memory) {
    AdventureUri.Adventure memory adventure = adventures[token];
    Combat.Combatant[] memory turn_order = turn_orders[token];
    return AdventureUri.tokenURI(token, adventure, turn_order, loadout(token), monster_ids(turn_order, adventure.monster_count));
  }
}