import { ethers, network } from 'hardhat'
import {promises as fs} from 'fs'
import getContracts from './contracts'
import { classes } from '../../test/util/classes'
import { skills, skillsArray } from '../../test/util/skills'
import { feats } from '../../test/util/feats'
import { craftingSkills } from '../../test/util/crafting'

async function jumpOneDay() {
  await network.provider.send('evm_increaseTime', [1 * 24 * 60 * 60])
  await network.provider.send('evm_mine')
}

async function dailyAdventure(contracts: any, summoner: any) {
  await contracts.rarity.adventure(summoner)
  await jumpOneDay()
}

async function trainSummoner(
  contracts: any, 
  summonerClass: number, 
  abilities: number[], 
  level: number,
  skills?: number[]
) {
  const result = await contracts.rarity.next_summoner()
  await(await contracts.rarity.summon(summonerClass)).wait()
  await(await contracts.attributes.point_buy(result, ...abilities)).wait()
  for(let i = 1; i < level; i++) {
    console.log('start level', i + 1, 'training')
    const xpToNextLevel = (i * (i + 1) / 2) * 1000
    const adventuresToNextLevel = xpToNextLevel / 250
    for(let j = 0; j < adventuresToNextLevel; j++) {
      await dailyAdventure(contracts, result)
    }
    await contracts.rarity.level_up(result)
  }
  if(skills) {
    console.log('train skills')
    await contracts.skills.set_skills(result, skills)
  }

  return result
}

async function trainCrafter({contracts, level = 1, craftingSkill}:{contracts: any, level?: number, craftingSkill: number}) {
  console.log('-- train level', level, 'crafter ---------------- }~-')
  const adventurer = await trainSummoner(
    contracts, 
    classes.wizard, 
    [8, 8, 8, 21, 12, 8], 
    level,
    skillsArray({ index: skills.craft, ranks: level + 3})
  )

  console.log('train crafting skill')
  const craftingSkills = Array(5).fill(0)
  craftingSkills[craftingSkill - 1] = level + 3
  await contracts.craftingSkills.set_skills(adventurer, craftingSkills)

  if(level > 3) {
    console.log('+1 intelligence')
    await contracts.attributes.increase_intelligence(adventurer)
  }

  const daysXpBudget = 100
  console.log('build', daysXpBudget, 'day XP budget')
  for(let i = 0; i < daysXpBudget; i++) {
    await dailyAdventure(contracts, adventurer)
  }

  console.log('setup class feats')
  await contracts.feats.setup_class(adventurer)

  console.log('💰 claim gold')
  await contracts.gold.claim(adventurer)

  return adventurer
}

async function trainFighter({contracts, level = 1}:{contracts: any, level?: number}) {
  console.log('-- train level', level, 'fighter ---------------- }~-')
  const adventurer = await trainSummoner(
    contracts, 
    classes.fighter, 
    [18, 14, 14, 12, 8, 8], 
    level,
    skillsArray({ index: skills.search, ranks: Math.floor((level + 3) / 2) })
  )

  if(level > 3) {
    console.log('+1 strength')
    await contracts.attributes.increase_strength(adventurer)
  }

  if(level > 7) {
    console.log('+1 strength')
    await contracts.attributes.increase_strength(adventurer)
  }

  console.log('setup class feats')
  await contracts.feats.setup_class(adventurer)
  console.log('take investigator feat')
  await contracts.feats.select_feat(adventurer, feats.investigator + 1)

  console.log('💰 claim gold')
  await contracts.gold.claim(adventurer)

  return adventurer
}

async function main() {
  const contracts = await getContracts()

  const crafters = []
  crafters.push(await trainCrafter({ contracts, level: 6, craftingSkill: craftingSkills.weaponsmithing }))
  crafters.push(await trainCrafter({ contracts, level: 6, craftingSkill: craftingSkills.armorsmithing }))

  const fighters = []
  for(let level = 1; level < 11; level++) {
    const fighter = await trainFighter({ contracts, level })
    fighters.push(fighter.toString())
  }

  console.log('write party.json')
  await fs.writeFile('./scripts/integration-test/party.json', JSON.stringify({
    crafters, fighters
  }, null, '\t'))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})