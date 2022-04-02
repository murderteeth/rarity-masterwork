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

  int8 public constant MONSTER_INITIATIVE_BONUS = 1;
  uint8 public constant MONSTER_DEX = 13;
  uint8 public constant MONSTER_AC = 15;
  uint8 public constant MONSTER_BASE_ATTACK_BONUS = 1;
  uint8 public constant MONSTER_CRITICAL_MULTIPLIER = 3;
  uint8 public constant MONSTER_HIT_DICE_COUNT = 1;
  uint8 public constant MONSTER_HIT_DICE_SIDES = 8;
  uint8 public constant MONSTER_DAMAGE_DICE_COUNT = 1;
  uint8 public constant MONSTER_DAMAGE_DICE_SIDES = 6;
  uint8 public constant MONSTER_DAMAGE_TYPE = 2;
  int8 public constant MONSTER_DAMAGE_ROLL_MODIFIER = -1;

  IRarity constant RARITY = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
  IRarityCodexCommonWeapons constant COMMON_WEAPONS_CODEX = IRarityCodexCommonWeapons(0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8);

  constructor() ERC721("Rarity Adventure II", "Adventure II") {}

  event SenseMotive(uint token, uint8 roll, int8 score);
  event RollInitiative(uint token, uint8 roll, int8 score);
  event Attack(uint token, uint attacker, uint defender, bool hit, uint8 roll, uint8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type);
  event Dying(uint token, uint combatant);

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
  mapping(uint => Combatant[]) public turn_orders;
  mapping(uint => uint) public summoners_turns;
  mapping(uint => uint) public current_turns;

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

  function enter_dungeon(uint token) public approvedForAdventure(token) onlyDuringActI(token) {
    Adventure storage adventure = adventures[token];
    adventure.dungeon_entered = true;
    adventure.monster_count = 2;
    uint8 number_of_combatants = adventure.monster_count + 1;

    Combatant[] memory combatants = new Combatant[](number_of_combatants);
    combatants[0] = summoner_combatant(token, adventure.summoner);
    for(uint i = 0; i < adventure.monster_count; i ++) {
      combatants[i + 1] = monster_combatant();
    }

    Combat.sort_by_initiative(combatants);
    Combatant[] storage turn_order = turn_orders[token];
    for(uint i = 0; i < number_of_combatants; i++) {
      turn_order.push(combatants[i]);
    }

    adventure.combat_round = 1;
    set_summoners_turn(token, combatants);
    combat_loop_until_summoners_next_turn(token);
  }

  function next_able_monster(uint token) public view returns(uint monsters_turn_order) {
    Combatant[] storage turn_order = turn_orders[token];
    uint turn_count = turn_order.length;
    for(uint i = 0; i < turn_count; i++) {
      Combatant storage combatant = turn_order[i];
      if(!combatant.summoner && combatant.hit_points > -1) return i;
    }
    revert("no able monster");
  }

  function attack(uint token, uint target) public approvedForAdventure(token) onlyDuringActII(token) {
    Adventure storage adventure = adventures[token];

    uint summoners_turn = summoners_turns[token];
    uint current_turn = current_turns[token];
    require(current_turn == summoners_turn, "!summoners_turn");

    Combatant[] storage turn_order = turn_orders[token];
    Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;
    require(target < turn_count, "target out of bounds");

    Combatant storage monster = turn_order[target];
    require(!monster.summoner, "monster.summoner");
    require(monster.hit_points > -1, "monster.hit_points < 0");

    attack_combatant(token, summoner, monster);
    if(monster.hit_points < 0) {
      adventure.monsters_defeated += 1;
      emit Dying(token, monster.token);
    }

    if(adventure.monsters_defeated == adventure.monster_count) {
      adventure.combat_ended = true;
    } else {
      current_turn = next_turn(adventure, turn_count, current_turn);  
      current_turns[token] = current_turn;  
      combat_loop_until_summoners_next_turn(token);
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

  function summoner_combatant(uint token, uint summoner) internal returns(Combatant memory combatant) {
    EquipmentSlot memory weapon_slot = equipment_slots[token][EQUIPMENT_TYPE_WEAPON];
    EquipmentSlot memory armor_slot = equipment_slots[token][EQUIPMENT_TYPE_ARMOR];
    codex.weapon memory weapon_codex = get_weapon_codex(weapon_slot);
    int8 base_weapon_modifier = Summoner.base_weapon_modifier(summoner, weapon_codex.encumbrance);

    Score memory initiative = Roll.initiative(summoner);
    emit RollInitiative(token, initiative.roll, initiative.score);

    combatant = Combatant({
      token: next_combatant,
      initiative: initiative,
      hit_points: int16(uint16(Summoner.hit_points(summoner))),
      base_weapon_modifier: base_weapon_modifier,
      total_attack_bonus: Summoner.total_attack_bonus(summoner, base_weapon_modifier),
      critical_modifier: int8(weapon_codex.critical_modifier),
      critical_multiplier: uint8(weapon_codex.critical),
      damage_dice_count: 1,
      damage_dice_sides: uint8(weapon_codex.damage),
      damage_type: uint8(weapon_codex.damage_type),
      armor_class: Summoner.armor_class(summoner, armor_slot.item, armor_slot.item_contract),
      summoner: true
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
    return codex.weapon(0, 0, 1, 0, 1, 0, 3, 2, 0, 0, "", "");
  }

  function monster_combatant() internal returns(Combatant memory combatant) {
    codex.weapon memory weapon_codex = COMMON_WEAPONS_CODEX.spear();
    Score memory initiative = Roll.initiative(next_combatant, Attributes.compute_modifier(MONSTER_DEX), 0);
    combatant = Combatant({
      token: next_combatant,
      initiative: initiative,
      hit_points: int16(uint16(Random.dn(9409069218745053777, next_combatant, MONSTER_HIT_DICE_COUNT, MONSTER_HIT_DICE_SIDES))),
      base_weapon_modifier: -1,
      total_attack_bonus: int8(MONSTER_BASE_ATTACK_BONUS),
      critical_modifier: int8(weapon_codex.critical_modifier),
      critical_multiplier: uint8(weapon_codex.critical),
      damage_dice_count: 1,
      damage_dice_sides: uint8(weapon_codex.damage),
      damage_type: uint8(weapon_codex.damage_type),
      armor_class: MONSTER_AC,
      summoner: false
    });
    next_combatant += 1;
  }

  function set_summoners_turn(uint token, Combatant[] memory combatants) internal {
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

    Combatant[] storage turn_order = turn_orders[token];
    Combatant storage summoner = turn_order[summoners_turn];
    uint turn_count = turn_order.length;

    do {
      Combatant memory monster = turn_order[current_turn];
      if(monster.hit_points > -1) attack_combatant(token, monster, summoner);
      current_turn = next_turn(adventure, turn_count, current_turn);
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

  function attack_combatant(uint token, Combatant memory attacker, Combatant storage defender) internal {
    (bool hit, uint8 roll, uint8 score, uint8 critical_confirmation, uint8 damage, uint8 damage_type) 
    = Combat.attack_combatant(attacker, defender);
    emit Attack(token, attacker.token, defender.token, hit, roll, score, critical_confirmation, damage, damage_type);
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