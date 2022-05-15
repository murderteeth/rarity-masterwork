import hre, { ethers, network } from 'hardhat'
import replace from 'replace-in-file'
import shell from 'shelljs'
import {promises as fs} from 'fs'
import devAddresses from '../addresses.dev.json'

async function main() {
  // await hre.run('clean')
  // await hre.run('compile')

  const codex_base_random_2 = await (await ethers.getContractFactory('contracts/codex/codex-base-random-2.sol:codex')).deploy()
  await codex_base_random_2.deployed()
  console.log('📐 deploy codex/codex-base-random-2.sol', codex_base_random_2.address)

  const codex_crafting_skills = await (await ethers.getContractFactory('contracts/codex/codex-crafting-skills.sol:codex')).deploy()
  await codex_crafting_skills.deployed()
  console.log('📐 deploy codex/codex-crafting-skills.sol', codex_crafting_skills.address)

  const codex_items_tools = await (await ethers.getContractFactory('contracts/codex/codex-items-tools.sol:codex')).deploy()
  await codex_items_tools.deployed()
  console.log('📐 deploy codex/codex-items-tools.sol', codex_items_tools.address)

  const codex_items_tools_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-tools-masterwork.sol:codex')).deploy()
  await codex_items_tools_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-tools-masterwork.sol', codex_items_tools_masterwork.address)

  const codex_items_weapons_2 = await (await ethers.getContractFactory('contracts/codex/codex-items-weapons-2.sol:codex')).deploy()
  await codex_items_weapons_2.deployed()
  console.log('📐 deploy codex/codex-items-weapons-2', codex_items_weapons_2.address)

  const codex_items_armor_2 = await (await ethers.getContractFactory('contracts/codex/codex-items-armor-2.sol:codex')).deploy()
  await codex_items_armor_2.deployed()
  console.log('📐 deploy codex/codex_items_armor_2', codex_items_armor_2.address)



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [
      new RegExp(devAddresses.codex_random_2, 'g'), 
      new RegExp(devAddresses.codex_weapons_2, 'g'), 
      new RegExp(devAddresses.codex_armor_2, 'g')
    ],
    to: [
      codex_base_random_2.address, 
      codex_items_weapons_2.address, 
      codex_items_armor_2.address
    ]
  })
  await hre.run('compile')

  

  const codex_items_weapons_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-weapons-masterwork.sol:codex')).deploy()
  await codex_items_weapons_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-weapons-masterwork.sol', codex_items_weapons_masterwork.address)

  const codex_items_armor_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-armor-masterwork.sol:codex')).deploy()
  await codex_items_armor_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-armor-masterwork.sol', codex_items_armor_masterwork.address)

  const library_rarity = await (await ethers.getContractFactory('contracts/library/Rarity.sol:Rarity')).deploy()
  await library_rarity.deployed()
  console.log('📚 deploy library/Rarity.sol', library_rarity.address)

  const library_skills = await (await ethers.getContractFactory('contracts/library/Skills.sol:Skills')).deploy()
  await library_skills.deployed()
  console.log('📚 deploy library/Skills.sol', library_skills.address)

  const library_attributes = await (await ethers.getContractFactory('contracts/library/Attributes.sol:Attributes')).deploy()
  await library_attributes.deployed()
  console.log('📚 deploy library/Attributes.sol', library_attributes.address)

  const library_crafting = await (await ethers.getContractFactory('contracts/library/Crafting.sol:Crafting')).deploy()
  await library_crafting.deployed()
  console.log('📚 deploy library/Crafting.sol', library_crafting.address)

  const library_feats = await (await ethers.getContractFactory('contracts/library/Feats.sol:Feats')).deploy()
  await library_feats.deployed()
  console.log('📚 deploy library/Feats.sol', library_feats.address)

  const library_proficiency = await (await ethers.getContractFactory('contracts/library/Proficiency.sol:Proficiency', {
    libraries: {
      Rarity: library_rarity.address,
      Feats: library_feats.address
    }
  })).deploy()
  await library_proficiency.deployed()
  console.log('📚 deploy library/Proficiency.sol', library_proficiency.address)

  const core_rarity_crafting_skills = await (await ethers.getContractFactory('contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills', {
    libraries: {
      Rarity: library_rarity.address,
      Skills: library_skills.address
    }
  })).deploy()
  await core_rarity_crafting_skills.deployed()
  console.log('🤺 deploy core/rarity_crafting_skills.sol', core_rarity_crafting_skills.address)

  const core_rarity_equipment_2 = await (await ethers.getContractFactory('contracts/core/rarity_equipment_2.sol:rarity_equipment_2', {
    libraries: {
      Rarity: library_rarity.address,
      Crafting: library_crafting.address
    }
  })).deploy()
  await core_rarity_equipment_2.deployed()
  console.log('🤺 deploy core/rarity_equipment_2.sol', core_rarity_equipment_2.address)



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [
      new RegExp(devAddresses.codex_crafting_skills, 'g'), 
      new RegExp(devAddresses.core_crafting_skills, 'g'),
      new RegExp(devAddresses.core_rarity_equipment_2, 'g')
    ],
    to: [
      codex_crafting_skills.address,
      core_rarity_crafting_skills.address,
      core_rarity_equipment_2.address
    ]
  })
  await hre.run('compile')



  const library_crafting_skills = await (await ethers.getContractFactory('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()
  await library_crafting_skills.deployed()
  console.log('📚 deploy library/CraftingSkills.sol', library_crafting_skills.address)

  const library_random = await (await ethers.getContractFactory('contracts/library/Random.sol:Random')).deploy()
  await library_random.deployed()
  console.log('📚 deploy library/Random.sol', library_random.address)

  const library_roll = await (await ethers.getContractFactory('contracts/library/Roll.sol:Roll', {
    libraries: {
      Attributes: library_attributes.address,
      CraftingSkills: library_crafting_skills.address,
      Feats: library_feats.address,
      Random: library_random.address,
      Skills: library_skills.address
    }
  })).deploy()
  await library_roll.deployed()
  console.log('📚 deploy library/Roll.sol', library_roll.address)

  const library_combat = await (await ethers.getContractFactory('contracts/library/Combat.sol:Combat')).deploy()
  await library_combat.deployed()
  console.log('📚 deploy library/Combat.sol', library_combat.address)

  const library_summoner = await (await ethers.getContractFactory('contracts/library/Summoner.sol:Summoner', {
    libraries: {
      Attributes: library_attributes.address,
      Proficiency: library_proficiency.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
    }
  })).deploy()
  await library_summoner.deployed()
  console.log('📚 deploy library/Summoner.sol', library_summoner.address)

  const library_monster = await (await ethers.getContractFactory('contracts/library/Monster.sol:Monster', {
    libraries: {
      Attributes: library_attributes.address,
      Random: library_random.address,
      Roll: library_roll.address,
    }
  })).deploy()
  await library_monster.deployed()
  console.log('📚 deploy library/Monster.sol', library_monster.address)

  const core_rarity_adventure_2_uri = await (await ethers.getContractFactory('contracts/core/rarity_adventure_2_uri.sol:adventure_uri', {
    libraries: {
      Monster: library_monster.address
    }
  })).deploy()
  await core_rarity_adventure_2_uri.deployed()
  console.log('🤺 deploy core/rarity_adventure_2_uri.sol', core_rarity_adventure_2_uri.address)

  const core_rarity_adventure_2 = await (await ethers.getContractFactory('contracts/core/rarity_adventure_2.sol:rarity_adventure_2', {
    libraries: {
      adventure_uri: core_rarity_adventure_2_uri.address,
      Monster: library_monster.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Summoner: library_summoner.address,
      Random: library_random.address
    }
  })).deploy()
  console.log('🤺 deploy core/rarity_adventure_2.sol', core_rarity_adventure_2.address)
  await core_rarity_adventure_2.deployed()




  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [new RegExp(devAddresses.core_adventure_2, 'g')],
    to: [core_rarity_adventure_2.address]
  })
  await hre.run('compile')



  const core_rarity_crafting_mats_2 = await (await ethers.getContractFactory('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')).deploy()
  console.log('🤺 deploy core/rarity_crafting-materials-2.sol', core_rarity_crafting_mats_2.address)
  await core_rarity_crafting_mats_2.deployed()


  ////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [
      new RegExp(devAddresses.core_rarity_crafting_mats_2, 'g'),
      new RegExp(devAddresses.codex_common_tools, 'g'),
      new RegExp(devAddresses.codex_weapons_masterwork, 'g'),
      new RegExp(devAddresses.codex_armor_masterwork, 'g'),
      new RegExp(devAddresses.codex_tools_masterwork, 'g')
    ],
    to: [
      core_rarity_crafting_mats_2.address,
      codex_items_tools.address,
      codex_items_weapons_masterwork.address,
      codex_items_armor_masterwork.address,
      codex_items_tools_masterwork.address
    ]
  })
  await hre.run('compile')

  const core_rarity_crafting_masterwork_uri = await (await ethers.getContractFactory('contracts/core/rarity_crafting_masterwork_uri.sol:masterwork_uri')).deploy()
  console.log('🤺 deploy core/core_rarity_crafting_masterwork_uri.sol', core_rarity_crafting_masterwork_uri.address)
  await core_rarity_crafting_masterwork_uri.deployed()

  const core_rarity_crafting_masterwork = await (await ethers.getContractFactory('contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork', {
    libraries: {
      Crafting: library_crafting.address,
      CraftingSkills: library_crafting_skills.address,
      masterwork_uri: core_rarity_crafting_masterwork_uri.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Skills: library_skills.address
    }
  })).deploy()
  await core_rarity_crafting_masterwork.deployed()
  console.log('🤺 deploy core/rarity_crafting_masterwork.sol', core_rarity_crafting_masterwork.address)

  {
    console.log()
    await(await core_rarity_equipment_2.set_mint_whitelist(
      '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC',
      codex_items_armor_2.address,
      codex_items_weapons_2.address,
      core_rarity_crafting_masterwork.address,
      codex_items_armor_masterwork.address,
      codex_items_weapons_masterwork.address
    )).wait()
    console.log('🏳  set adventure 2 whitelist')
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
    core_rarity_crafting_masterwork: { 
      address: core_rarity_crafting_masterwork.address,
      contract: 'contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork',
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

  console.log('\n\n💥 deployed!!\n\n')
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