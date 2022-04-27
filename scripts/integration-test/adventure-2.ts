import { ethers } from 'hardhat'
import deployAddresses from '../../deploy-addresses.json'
import { classes } from '../../test/util/classes'
import { getDamageType } from '../../test/util'
import monsterCodex from '../../test/util/monster-codex.json'

async function contracts() {
  return {
    rarity: await ethers.getContractAt(
      'contracts/core/rarity.sol:rarity',
      '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb'
    ),
    attributes: await ethers.getContractAt(
      'contracts/core/attributes.sol:rarity_attributes',
      '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1'
    ),
    adventure2: await ethers.getContractAt(
      'contracts/core/rarity_adventure-2.sol:rarity_adventure_2', 
      deployAddresses.core_rarity_adventure_2
    ),
    mats2: await ethers.getContractAt(
      'contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2',
      deployAddresses.core_crafting_mats_2
    ),
    masterwork: await ethers.getContractAt(
      'contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork', 
      deployAddresses.core_rarity_crafting_masterwork
    ),
  }  
}

async function trainSummoner(contracts: any, summonerClass: number, abilities: number[]) {
  const result = await contracts.rarity.next_summoner()
  await(await contracts.rarity.summon(summonerClass)).wait()
  await(await contracts.attributes.point_buy(result, ...abilities)).wait()
  return result
}

async function trainFighter(rarity: any) {
  const adventurer = await trainSummoner(rarity, 
    classes.fighter, [18, 12, 13, 11, 8, 12])
  return adventurer
}

async function trainMonk(rarity: any) {
  const adventurer = await trainSummoner(rarity, 
    classes.monk, [18, 12, 13, 11, 12, 8])
  return adventurer
}

async function getTurnOrder(contracts: any, adventureToken: any) {
  const turnOrder = []
  const adventure = await contracts.adventure2.adventures(adventureToken)
  for(let i = 0; i < adventure.monster_count + 1; i++) {
    turnOrder.push(await contracts.adventure2.turn_orders(adventureToken, i))
  }
  return { adventure, turnOrder }
}

async function getMonster(contracts: any, combatantToken: any) {
  const monsterId = await contracts.adventure2.monster_spawn(combatantToken)
  return monsterCodex.find((monster: any) => monster.id === monsterId)?.name
}

async function getInititalTurnOrder(contracts: any, summoner: any, adventureToken: any) {
  const initialSummoner = await contracts.adventure2.preview(summoner, 0, ethers.constants.AddressZero, 0, ethers.constants.AddressZero, 0, ethers.constants.AddressZero)
  const { adventure, turnOrder } = await getTurnOrder(contracts, adventureToken)
  const index = turnOrder.findIndex((combatant: any) => combatant.token.eq(initialSummoner.token))
  turnOrder[index] = { ...initialSummoner, initiative: turnOrder[index].initiative }
  return turnOrder
}

async function logTurnOrder(contracts: any, turnOrder: any) {
  console.log('\ncombatants ---------------------')
  for(let i = 0; i < turnOrder.length; i++) {
    const combatant = turnOrder[i]
    const type = combatant['origin'] === contracts.rarity.address ? 'summoner' : await getMonster(contracts, combatant['token'])
    console.log(type, 'hp', combatant['hit_points'], 'ac', combatant['armor_class'], 'initiative', combatant['initiative_score'])
  }  
}

async function logAttacks(contracts: any, adventureToken: any, tx: any) {
  const { adventure, turnOrder } = await getTurnOrder(contracts, adventureToken)
  const summonersTurn = await contracts.adventure2.summoners_turns(adventureToken)
  for(let i = 0; i < tx.events.length; i++) {
    if(tx.events[i].event === 'Attack') {
      const args = tx.events[i].args
      const attacker = turnOrder[args['attacker'].toNumber()]
      const defender = turnOrder[args['defender'].toNumber()]
      const attacker_name = args['attacker'].eq(summonersTurn) ? 'Summoner' : await getMonster(contracts, attacker.token)
      const defender_name = args['defender'].eq(summonersTurn) ? 'Summoner' : await getMonster(contracts, defender.token)

      if(args['hit']) {
        const critical = args['critical_confirmation'] >= defender.armor_class
        console.log(
          'round', args['round'],
          critical ? `🎆 ${attacker_name} crits ${defender_name} for` : `💥 ${attacker_name} hits ${defender_name} for`, 
          args['damage'], 'points of', getDamageType(args['damage_type']), 'damage',
          '::', args['roll'], args['score'], args['critical_confirmation']
        )
      } else {
        console.log(
          'round', args['round'], `🤡 ${attacker_name} misses ${defender_name}`, '::', args['roll'], args['score'], args['critical_confirmation']
        )
      }

    } else if(tx.events[i].event === 'Dying') {
      const args = tx.events[i].args
      const combatant = turnOrder[args['combatant']]
      const combatant_name = args['combatant'].eq(summonersTurn) ? 'Summoner' : await getMonster(contracts, combatant.token)
      console.log('round', args['round'], '💀', combatant_name, 'is no longer')

    }
  }
}

async function adventure(contracts: any) {
  const gasLimit = 1_000_000
  console.log()
  //const adventurer = await trainFighter(contracts)
  const adventurer = await trainMonk(contracts)

  await contracts.rarity.approve(contracts.adventure2.address, adventurer)
  const startTx = await(await contracts.adventure2.start(adventurer)).wait()
  const adventureToken = startTx.events[3].args.tokenId

  console.log(`-- Adventure ${adventureToken.toString()} ---------------- }~-`)
  console.log('-- Level 1 Monk')
  console.log('-- Unarmed')

  const enterTx = await(await contracts.adventure2.enter_dungeon(adventureToken, { gasLimit })).wait()
  const initialTurnOrder = await getInititalTurnOrder(contracts, adventurer, adventureToken)
  await logTurnOrder(contracts, initialTurnOrder)
  console.log()
  await logAttacks(contracts, adventureToken, enterTx)

  while(!(await contracts.adventure2.adventures(adventureToken)).combat_ended) {
    const target = await contracts.adventure2.next_able_monster(adventureToken)
    const attackTx = await(await contracts.adventure2.attack(adventureToken, target, { gasLimit })).wait()
    await logAttacks(contracts, adventureToken, attackTx)
  }

  await logTurnOrder(contracts, (await getTurnOrder(contracts, adventureToken)).turnOrder)
  await contracts.adventure2.end(adventureToken)

  const adventure = await contracts.adventure2.adventures(adventureToken)
  if(adventure.monsters_defeated === adventure.monster_count) {
    const claimTx = await(await contracts.mats2.claim(adventureToken)).wait()
    const transferArgs = claimTx.events.find((e: any) => e.event === 'Transfer').args
    console.log('\n💰 VICTORY!', ethers.utils.formatEther(transferArgs['value']), 'mats claimed')
  }

  console.log()
}

async function main() {
  const CONTRACTS = await contracts()
  for(let i = 0; i < 10; i++) {
    await adventure(CONTRACTS)
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})