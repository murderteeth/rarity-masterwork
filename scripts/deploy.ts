import hre, { ethers, network } from 'hardhat'
import replace from 'replace-in-file'
import shell from 'shelljs'
import {promises as fs} from 'fs'
import devAddresses from '../addresses.dev.json'

async function deploy(contract: string, options?: object) {
  const deployment = await (await ethers.getContractFactory(contract, options)).deploy()
  console.log('✨ deploy', contract, deployment.address)
  await deployment.deployed()  
  return deployment
}

async function updateRefsAndRecompile(replaceExpressions: RegExp[], withAddresses: string[] ) {
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: replaceExpressions,
    to: withAddresses
  })
  await hre.run('compile')
}

async function main() {
  await hre.run('clean')
  await hre.run('compile')

  const codex_base_random_2 = await deploy('contracts/codex/codex-base-random-2.sol:codex')
  const codex_crafting_skills = await deploy('contracts/codex/codex-crafting-skills.sol:codex')
  const codex_items_tools = await deploy('contracts/codex/codex-items-tools.sol:codex')
  const codex_items_tools_masterwork = await deploy('contracts/codex/codex-items-tools-masterwork.sol:codex')
  const codex_items_weapons_2 = await deploy('contracts/codex/codex-items-weapons-2.sol:codex')
  const codex_items_armor_2 = await deploy('contracts/codex/codex-items-armor-2.sol:codex')

  await updateRefsAndRecompile(
    [
      new RegExp(devAddresses.codex_random_2, 'g'),
      new RegExp(devAddresses.codex_weapons_2, 'g'),
      new RegExp(devAddresses.codex_armor_2, 'g')
    ], [
      codex_base_random_2.address, 
      codex_items_weapons_2.address, 
      codex_items_armor_2.address
    ]
  )

  const codex_items_weapons_masterwork = await deploy('contracts/codex/codex-items-weapons-masterwork.sol:codex')
  const codex_items_armor_masterwork = await deploy('contracts/codex/codex-items-armor-masterwork.sol:codex')
  const library_rarity = await deploy('contracts/library/Rarity.sol:Rarity')
  const library_skills = await deploy('contracts/library/Skills.sol:Skills')
  const library_attributes = await deploy('contracts/library/Attributes.sol:Attributes')
  const library_crafting = await deploy('contracts/library/Crafting.sol:Crafting')
  const library_feats = await deploy('contracts/library/Feats.sol:Feats')
  const library_proficiency = await deploy('contracts/library/Proficiency.sol:Proficiency', {
    libraries: {
      Rarity: library_rarity.address,
      Feats: library_feats.address
    }
  })
  const core_rarity_crafting_skills = await deploy('contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills', {
    libraries: {
      Rarity: library_rarity.address,
      Skills: library_skills.address
    }
  })
  const core_rarity_equipment_2 = await deploy('contracts/core/rarity_equipment_2.sol:rarity_equipment_2', {
    libraries: {
      Rarity: library_rarity.address,
      Crafting: library_crafting.address
    }
  })

  await updateRefsAndRecompile(
    [
      new RegExp(devAddresses.codex_crafting_skills, 'g'), 
      new RegExp(devAddresses.core_crafting_skills, 'g'),
      new RegExp(devAddresses.core_rarity_equipment_2, 'g')
    ], [
      codex_crafting_skills.address,
      core_rarity_crafting_skills.address,
      core_rarity_equipment_2.address
    ]
  )

  const library_crafting_skills = await deploy('contracts/library/CraftingSkills.sol:CraftingSkills')
  const library_random = await deploy('contracts/library/Random.sol:Random')
  const library_roll = await deploy('contracts/library/Roll.sol:Roll', {
    libraries: {
      Attributes: library_attributes.address,
      CraftingSkills: library_crafting_skills.address,
      Feats: library_feats.address,
      Random: library_random.address,
      Skills: library_skills.address
    }
  })
  const library_combat = await deploy('contracts/library/Combat.sol:Combat')
  const library_summoner = await deploy('contracts/library/Summoner.sol:Summoner', {
    libraries: {
      Attributes: library_attributes.address,
      Proficiency: library_proficiency.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
    }
  })
  const library_monster = await deploy('contracts/library/Monster.sol:Monster', {
    libraries: {
      Attributes: library_attributes.address,
      Random: library_random.address,
      Roll: library_roll.address,
    }
  })
  const core_rarity_adventure_2_uri = await deploy('contracts/core/rarity_adventure_2_uri.sol:adventure_uri', {
    libraries: {
      Monster: library_monster.address
    }
  })
  const core_rarity_adventure_2 = await deploy('contracts/core/rarity_adventure_2.sol:rarity_adventure_2', {
    libraries: {
      adventure_uri: core_rarity_adventure_2_uri.address,
      Monster: library_monster.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Summoner: library_summoner.address,
      Random: library_random.address
    }
  })

  await updateRefsAndRecompile(
    [new RegExp(devAddresses.core_adventure_2, 'g')], 
    [core_rarity_adventure_2.address]
  )

  const core_rarity_crafting_mats_2 = await deploy('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')

  await updateRefsAndRecompile(
    [
      new RegExp(devAddresses.core_rarity_crafting_mats_2, 'g'),
      new RegExp(devAddresses.codex_common_tools, 'g'),
      new RegExp(devAddresses.codex_weapons_masterwork, 'g'),
      new RegExp(devAddresses.codex_armor_masterwork, 'g'),
      new RegExp(devAddresses.codex_tools_masterwork, 'g')
    ], [
      core_rarity_crafting_mats_2.address,
      codex_items_tools.address,
      codex_items_weapons_masterwork.address,
      codex_items_armor_masterwork.address,
      codex_items_tools_masterwork.address
    ]
  )

  const core_rarity_crafting_masterwork_uri = await deploy('contracts/core/rarity_crafting_masterwork_uri.sol:masterwork_uri')
  const core_rarity_crafting_masterwork_items = await deploy('contracts/core/rarity_crafting_masterwork_items.sol:rarity_masterwork_items', {
    libraries: {
      Crafting: library_crafting.address,
      masterwork_uri: core_rarity_crafting_masterwork_uri.address,
      Rarity: library_rarity.address
    }
  })

  await updateRefsAndRecompile(
    [new RegExp(devAddresses.core_masterwork_items, 'g'),], 
    [core_rarity_crafting_masterwork_items.address]
  )

  const core_rarity_crafting_masterwork_projects = await deploy('contracts/core/rarity_crafting_masterwork_projects.sol:rarity_masterwork_projects', {
    libraries: {
      Crafting: library_crafting.address,
      CraftingSkills: library_crafting_skills.address,
      masterwork_uri: core_rarity_crafting_masterwork_uri.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Skills: library_skills.address
    }
  })

  {
    console.log()
    await(await core_rarity_crafting_masterwork_items.set_project_mint(
      core_rarity_crafting_masterwork_projects.address,
    )).wait()
    console.log('🏳  set masterwork project mint')

    await(await core_rarity_equipment_2.set_mint_whitelist(
      '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC',
      codex_items_armor_2.address,
      codex_items_weapons_2.address,
      core_rarity_crafting_masterwork_items.address,
      codex_items_armor_masterwork.address,
      codex_items_weapons_masterwork.address
    )).wait()
    console.log('🏳  set equipment 2 whitelist')

    console.log()
  }

  const addressFile = `./addresses.${network.name}.json`

  await fs.writeFile(addressFile, JSON.stringify({
    codex_base_random_2: { 
      address: codex_base_random_2.address,
      contract: 'contracts/codex/codex-base-random-2.sol:codex',
      verified: false
    },
    codex_crafting_skills: { 
      address: codex_crafting_skills.address,
      contract: 'contracts/codex/codex-crafting-skills.sol:codex',
      verified: false
    },
    codex_items_armor_2: { 
      address: codex_items_armor_2.address,
      contract: 'contracts/codex/codex_items_armor_2:codex',
      verified: false
    },
    codex_items_armor_masterwork: { 
      address: codex_items_armor_masterwork.address,
      contract: 'contracts/codex/codex-items-armor-masterwork.sol:codex',
      verified: false
    },
    codex_items_tools: { 
      address: codex_items_tools.address,
      contract: 'contracts/codex/codex-items-tools.sol:codex',
      verified: false
    },
    codex_items_tools_masterwork: { 
      address: codex_items_tools_masterwork.address,
      contract: 'contracts/codex/codex-items-tools-masterwork.sol:codex',
      verified: false
    },
    codex_items_weapons_2: { 
      address: codex_items_weapons_2.address,
      contract: 'contracts/codex/codex-items-weapons-2:codex',
      verified: false
    },
    codex_items_weapons_masterwork: { 
      address: codex_items_weapons_masterwork.address,
      contract: 'contracts/codex/codex-items-weapons-masterwork.sol:codex',
      verified: false
    },
    library_attributes: { 
      address: library_attributes.address,
      contract: 'contracts/library/Attributes.sol:Attributes',
      verified: false
    },
    library_combat: { 
      address: library_combat.address,
      contract: 'contracts/library/Combat.sol:Combat',
      verified: false
    },
    library_crafting: { 
      address: library_crafting.address,
      contract: 'contracts/library/Crafting.sol:Crafting',
      verified: false
    },
    library_crafting_skills: { 
      address: library_crafting_skills.address,
      contract: 'contracts/library/CraftingSkills.sol:CraftingSkills',
      verified: false
    },
    library_feats: { 
      address: library_feats.address,
      contract: 'contracts/library/Feats.sol:Feats',
      verified: false
    },
    library_proficiency: { 
      address: library_proficiency.address,
      contract: 'contracts/library/Proficiency.sol:Proficiency',
      verified: false
    },
    library_random: { 
      address: library_random.address,
      contract: 'contracts/library/Random.sol:Random',
      verified: false
    },
    library_rarity: { 
      address: library_rarity.address,
      contract: 'contracts/library/Rarity.sol:Rarity',
      verified: false
    },
    library_roll: { 
      address: library_roll.address,
      contract: 'contracts/library/Roll.sol:Roll',
      verified: false
    },
    library_skills: { 
      address: library_skills.address,
      contract: 'contracts/library/Skills.sol:Skills',
      verified: false
    },
    library_summoner: { 
      address: library_summoner.address,
      contract: 'contracts/library/Summoner.sol:Summoner',
      verified: false
    },
    core_rarity_crafting_skills: { 
      address: core_rarity_crafting_skills.address,
      contract: 'contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills',
      verified: false
    },
    core_rarity_equipment_2: { 
      address: core_rarity_equipment_2.address,
      contract: 'contracts/core/rarity_equipment_2.sol:rarity_equipment_2',
      verified: false
    },
    library_monster: { 
      address: library_monster.address,
      contract: 'contracts/library/Monster.sol:Monster',
      verified: false
    },
    core_rarity_adventure_2: { 
      address: core_rarity_adventure_2.address,
      contract: 'contracts/core/rarity_adventure_2.sol:rarity_adventure_2',
      verified: false
    },
    core_rarity_adventure_2_uri: { 
      address: core_rarity_adventure_2_uri.address,
      contract: 'contracts/core/rarity_adventure_2_uri.sol:adventure_uri',
      verified: false
    },
    core_rarity_crafting_masterwork_uri: { 
      address: core_rarity_crafting_masterwork_uri.address,
      contract: 'contracts/core/rarity_crafting_masterwork_uri.sol:masterwork_uri',
      verified: false
    },
    core_rarity_crafting_masterwork_items: { 
      address: core_rarity_crafting_masterwork_items.address,
      contract: 'contracts/core/rarity_crafting_masterwork_items.sol:rarity_masterwork_items',
      verified: false
    },
    core_rarity_crafting_masterwork_projects: { 
      address: core_rarity_crafting_masterwork_projects.address,
      contract: 'contracts/core/rarity_crafting_masterwork_projects.sol:rarity_masterwork_projects',
      verified: false
    },
    core_rarity_crafting_mats_2: { 
      address: core_rarity_crafting_mats_2.address,
      contract: 'contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2',
      verified: false
    }
  }, null, '\t'))

  console.log('📝 write deployed addresses to ', addressFile)

  if(network.name === 'localhost') {
    shell.exec('git checkout contracts/*')
  }

  console.log('\n\n🍻 deployed!!\n\n')
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error)
  console.log()
  if(network.name === 'localhost') {
    console.log('reset contracts, git checkout contracts/*')
    shell.exec('git checkout contracts/*')
  }
  console.log()
  console.log()
  process.exit(1)
})