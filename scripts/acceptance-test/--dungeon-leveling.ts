import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { equipmentSlot, getDamageType } from '../../util'
import { fakeAttributes, fakeCommonCrafting, fakeEquipment, fakeFeats, fakeFullPlateArmor, fakeGreatsword, fakeMasterworkProjects, fakeRarity, fakeSkills, fakeSummoner } from '../../util/fakes'
import { Attributes__factory, Feats__factory, Monster__factory, Proficiency__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { classes } from '../../util/classes'
import { armorType, weaponType } from '../../util/crafting'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { armors, weapons } from '../../util/equipment'
import monsterCodex from '../../util/monster-codex.json'
import { jumpOneDay, jumpOneMinute } from '../../util/jump'
import devAddresses from '../../addresses.dev.json'
import { adventure_uri__factory } from '../../typechain/core'

async function getTurnOrder(fixture: any, adventureToken: any) {
  const turnOrder = []
  const adventure = await fixture.adventure.adventures(adventureToken)
  for(let i = 0; i < adventure.monster_count + 1; i++) {
    turnOrder.push(await fixture.adventure.turn_orders(adventureToken, i))
  }
  return { adventure, turnOrder }
}

async function getMonster(fixture: any, combatantToken: any) {
  const monsterId = await fixture.adventure.monster_spawn(combatantToken)
  return monsterCodex.find((monster: any) => monster.id === monsterId)?.name
}

async function getInititalTurnOrder(fixture: any, initialSummoner: any, adventureToken: any) {
  const { adventure, turnOrder } = await getTurnOrder(fixture, adventureToken)
  const index = turnOrder.findIndex((combatant: any) => combatant.token.eq(initialSummoner.token))
  turnOrder[index] = { ...initialSummoner, initiative_roll: turnOrder[index]['initiative_roll'], initiative_score: turnOrder[index]['initiative_score'] }
  return turnOrder
}

async function logTurnOrder(fixture: any, turnOrder: any) {
  for(let i = 0; i < turnOrder.length; i++) {
    const combatant = turnOrder[i]
    const type = combatant['origin'] === fixture.core.rarity.address ? 'Summoner' : await getMonster(fixture, combatant['token'])
    console.log(type, 'hp', combatant['hit_points'], 'ac', combatant['armor_class'], 'initiative', combatant['initiative_score'])
  }  
}

async function logAttacks(fixture: any, adventureToken: any, tx: any) {
  const { adventure, turnOrder } = await getTurnOrder(fixture, adventureToken)
  const summonersTurn = await fixture.adventure.summoners_turns(adventureToken)
  for(let i = 0; i < tx.events.length; i++) {
    if(tx.events[i].event === 'Attack') {
      const args = tx.events[i].args
      const attacker = turnOrder[args['attacker'].toNumber()]
      const defender = turnOrder[args['defender'].toNumber()]
      const attacker_name = args['attacker'].eq(summonersTurn) ? 'Summoner' : await getMonster(fixture, attacker.token)
      const defender_name = args['defender'].eq(summonersTurn) ? 'Summoner' : await getMonster(fixture, defender.token)

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
      const combatant_name = args['combatant'].eq(summonersTurn) ? 'Summoner' : await getMonster(fixture, combatant.token)
      console.log('round', args['round'], '💀', combatant_name, 'is no longer')

    }
  }
}

async function mockAdvenutreUri() {
  return await(await smock.mock<adventure_uri__factory>('contracts/core/rarity_adventure_2_uri.sol:adventure_uri', {
    libraries: {
      Monster: (await(await smock.mock<Monster__factory>('contracts/library/Monster.sol:Monster', {
        libraries: {
          Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
            libraries: {
              Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
              Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
              Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
              Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
              CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
            }
          })).deploy()).address
        }
      })).deploy()).address
    }
  })).deploy()
}

async function mockAdventure(adventure_uri: any) {
  return await(await smock.mock<RarityAdventure2__factory>('contracts/core/rarity_adventure_2.sol:rarity_adventure_2', {
    libraries: {
      adventure_uri: adventure_uri.address,
      Monster: (await(await smock.mock<Monster__factory>('contracts/library/Monster.sol:Monster', {
        libraries: {
          Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
            libraries: {
              Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
              Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
              Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
              Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
              CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
            }
          })).deploy()).address
        }
      })).deploy()).address,
      Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
      Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
        libraries: {
          Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
          Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
          CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
        }
      })).deploy()).address,
      Summoner: (await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner', {
        libraries: {
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Proficiency: (await (await smock.mock<Proficiency__factory>('contracts/library/Proficiency.sol:Proficiency', {
            libraries: {
              Feats: (await (await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
              Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
            }
          })).deploy()).address,
          Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
          Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
            libraries: {
              Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
              Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
              Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
              Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
              CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
            }
          })).deploy()).address
        }
      })).deploy()).address,
      Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address
    }
  })).deploy()
}

async function simulateAdventure(fixture: any, logging: boolean) {
  await jumpOneDay()
  const token = await fixture.adventure.next_token()
  await fixture.adventure.start(fixture.summoner)

  fixture.equipment.snapshots
  .whenCalledWith(fixture.adventure.address, token, fixture.summoner, equipmentSlot.weapon1)
  .returns([fixture.crafting.common.address, fixture.greatsword])
  fixture.equipment.snapshots
  .whenCalledWith(fixture.adventure.address, token, fixture.summoner, equipmentSlot.armor)
  .returns([fixture.crafting.common.address, fixture.fullPlate])

  const enterTx = await(await fixture.adventure.enter_dungeon(token)).wait()
  if(logging) await logAttacks(fixture, token, enterTx)

  while(!(await fixture.adventure.adventures(token)).combat_ended) {
    const target = await fixture.adventure.next_able_monster(token)
    const attackTx = await(await fixture.adventure.attack(token, target)).wait()
    if(logging) await logAttacks(fixture, token, attackTx)
    await jumpOneMinute()
  }

  if(logging) await logTurnOrder(fixture, (await getTurnOrder(fixture, token)).turnOrder)

  const adventure = await fixture.adventure.adventures(token)
  if(adventure.monsters_defeated === adventure.monster_count) {
    if(logging) console.log('VICTORY 🏆')
    await fixture.adventure.end(token)
    return true
  } else {
    if(logging) console.log('DEFEAT 😭')
    await fixture.adventure.end(token)
    return false
  }
}

async function main() {
  console.log('🤺 start combat sim')

  const signers = await ethers.getSigners()
  const signer = signers[0]

  const codex = {
    common: {
      armor: await smock.fake('contracts/codex/codex-items-armor-2.sol:codex', { address: devAddresses.codex_armor_2 }),
      weapons: await smock.fake('contracts/codex/codex-items-weapons-2.sol:codex', { address: devAddresses.codex_weapons_2 })
    },
    masterwork: {
      armor: await smock.fake('contracts/codex/codex-items-armor-masterwork.sol:codex', { address: devAddresses.codex_armor_masterwork }),
      weapons: await smock.fake('contracts/codex/codex-items-weapons-masterwork.sol:codex', { address: devAddresses.codex_weapons_masterwork })
    }
  }

  const core = {
    rarity: await fakeRarity(),
    attributes: await fakeAttributes(),
    skills: await fakeSkills(),
    feats: await fakeFeats()
  }

  const crafting = {
    common: await fakeCommonCrafting(),
    masterwork: await fakeMasterworkProjects()
  }

  const equipment = await fakeEquipment()
  equipment.codexes
  .whenCalledWith(crafting.common.address, 2)
  .returns(codex.common.armor.address)
  equipment.codexes
  .whenCalledWith(crafting.common.address, 3)
  .returns(codex.common.weapons.address)
  equipment.codexes
  .whenCalledWith(crafting.masterwork.address, 2)
  .returns(codex.masterwork.armor.address)
  equipment.codexes
  .whenCalledWith(crafting.masterwork.address, 3)
  .returns(codex.masterwork.weapons.address)

  codex.common.weapons.item_by_id
  .whenCalledWith(weaponType.greatsword)
  .returns(weapons('greatsword'))
  codex.common.weapons.item_by_id
  .whenCalledWith(weaponType.longsword)
  .returns(weapons('longsword'))
  codex.common.armor.item_by_id
  .whenCalledWith(armorType.fullPlate)
  .returns(armors('full plate'))
  codex.common.armor.item_by_id
  .whenCalledWith(armorType.heavyWoodShield)
  .returns(armors('shield, heavy wooden'))

  const adventure_uri = await mockAdvenutreUri()
  const adventure = await mockAdventure(adventure_uri)

  const summoner = fakeSummoner(core.rarity, signer)

  core.rarity.class
  .whenCalledWith(summoner)
  .returns(classes.fighter)

  const greatsword = fakeGreatsword(crafting.common, summoner, signer)
  const fullPlate = fakeFullPlateArmor(crafting.common, summoner, signer)

  const fixture = { signers, signer, core, crafting, equipment, adventure, summoner, greatsword, fullPlate }

  const minLevel = 1
  const maxLevel = 10
  const samples = 50
  for(let level = minLevel; level <= maxLevel; level++) {
    core.rarity.level
    .whenCalledWith(summoner)
    .returns(level)

    const strength = 18 + Math.floor(level / 4)
    core.attributes.ability_scores
    .whenCalledWith(summoner)
    .returns([strength, 14, 14, 12, 8, 8])

    let wins = 0
    process.stdout.write('level ' + level + ' ')
    for(let j = 0; j < samples; j++) {
      if(await simulateAdventure(fixture, false)) {
        process.stdout.write('🏆')
        wins++
      } else {
        process.stdout.write('🤡')
      }
    }
    console.log(' win rate', 100 * wins / samples, '%')
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})