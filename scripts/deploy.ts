import hre, { ethers, network } from 'hardhat'
import replace from 'replace-in-file'
import shell from 'shelljs'
import {promises as fs} from 'fs'
import devAddresses from '../dev-addresses.json'

async function main() {
  // await hre.run('clean')
  // await hre.run('compile')


  const codex_crafting_skills = await (await ethers.getContractFactory('contracts/codex/codex-crafting-skills.sol:codex')).deploy()
  await codex_crafting_skills.deployed()
  console.log('📐 deploy codex/codex-crafting-skills.sol', codex_crafting_skills.address);

  const codex_items_tools = await (await ethers.getContractFactory('contracts/codex/codex-items-tools.sol:codex')).deploy()
  await codex_items_tools.deployed()
  console.log('📐 deploy codex/codex-items-tools.sol', codex_items_tools.address);

  const codex_items_tools_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-tools-masterwork.sol:codex')).deploy()
  await codex_items_tools_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-tools-masterwork.sol', codex_items_tools_masterwork.address);

  const codex_items_weapons_2 = await (await ethers.getContractFactory('contracts/codex/codex-items-weapons-2.sol:codex')).deploy()
  await codex_items_weapons_2.deployed()
  console.log('📐 deploy codex/codex-items-weapons-2', codex_items_weapons_2.address);

  const codex_items_armor_2 = await (await ethers.getContractFactory('contracts/codex/codex-items-armor-2.sol:codex')).deploy()
  await codex_items_armor_2.deployed()
  console.log('📐 deploy codex/codex_items_armor_2', codex_items_armor_2.address);



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [
      new RegExp(devAddresses.codex_weapons_2, 'g'), 
      new RegExp(devAddresses.codex_armor_2, 'g')
    ],
    to: [
      codex_items_weapons_2.address, 
      codex_items_armor_2.address
    ]
  })
  await hre.run('compile')

  

  const codex_items_weapons_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-weapons-masterwork.sol:codex')).deploy()
  await codex_items_weapons_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-weapons-masterwork.sol', codex_items_weapons_masterwork.address);

  const codex_items_armor_masterwork = await (await ethers.getContractFactory('contracts/codex/codex-items-armor-masterwork.sol:codex')).deploy()
  await codex_items_armor_masterwork.deployed()
  console.log('📐 deploy codex/codex-items-armor-masterwork.sol', codex_items_armor_masterwork.address);

  const library_rarity = await (await ethers.getContractFactory('contracts/library/Rarity.sol:Rarity')).deploy()
  await library_rarity.deployed()
  console.log('📚 deploy library/Rarity.sol', library_rarity.address);

  const library_skills = await (await ethers.getContractFactory('contracts/library/Skills.sol:Skills')).deploy()
  await library_skills.deployed()
  console.log('📚 deploy library/Skills.sol', library_skills.address);

  const library_attributes = await (await ethers.getContractFactory('contracts/library/Attributes.sol:Attributes')).deploy()
  await library_attributes.deployed()
  console.log('📚 deploy library/Attributes.sol', library_attributes.address);

  const library_crafting = await (await ethers.getContractFactory('contracts/library/Crafting.sol:Crafting')).deploy()
  await library_crafting.deployed()
  console.log('📚 deploy library/Crafting.sol', library_crafting.address);

  const library_feats = await (await ethers.getContractFactory('contracts/library/Feats.sol:Feats')).deploy()
  await library_feats.deployed()
  console.log('📚 deploy library/Feats.sol', library_feats.address);

  const library_proficiency = await (await ethers.getContractFactory('contracts/library/Proficiency.sol:Proficiency', {
    libraries: {
      Rarity: library_rarity.address,
      Feats: library_feats.address
    }
  })).deploy()
  await library_proficiency.deployed()
  console.log('📚 deploy library/Proficiency.sol', library_proficiency.address);

  const core_rarity_crafting_skills = await (await ethers.getContractFactory('contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills', {
    libraries: {
      Rarity: library_rarity.address,
      Skills: library_skills.address
    }
  })).deploy()
  await core_rarity_crafting_skills.deployed()
  console.log('🤺 deploy core/rarity_crafting_skills.sol', core_rarity_crafting_skills.address);



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [new RegExp(devAddresses.codex_crafting_skills, 'g'), new RegExp(devAddresses.core_crafting_skills, 'g')],
    to: [codex_crafting_skills.address, core_rarity_crafting_skills.address]
  })
  await hre.run('compile')



  const library_crafting_skills = await (await ethers.getContractFactory('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()
  await library_crafting_skills.deployed()
  console.log('📚 deploy library/CraftingSkills.sol', library_crafting_skills.address);

  const library_random = await (await ethers.getContractFactory('contracts/library/Random.sol:Random')).deploy()
  await library_random.deployed()
  console.log('📚 deploy library/Random.sol', library_random.address);

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
  console.log('📚 deploy library/Roll.sol', library_roll.address);

  const library_combat = await (await ethers.getContractFactory('contracts/library/Combat.sol:Combat')).deploy()
  await library_combat.deployed()
  console.log('📚 deploy library/Combat.sol', library_combat.address);

  const library_summoner = await (await ethers.getContractFactory('contracts/library/Summoner.sol:Summoner', {
    libraries: {
      Attributes: library_attributes.address,
      Proficiency: library_proficiency.address,
      Rarity: library_rarity.address
    }
  })).deploy()
  await library_summoner.deployed()
  console.log('📚 deploy library/Summoner.sol', library_summoner.address);

  const core_rarity_crafting_common_wrapper = await (await ethers.getContractFactory('contracts/core/rarity_crafting_common_wrapper.sol:rarity_crafting_wrapper')).deploy()
  await core_rarity_crafting_common_wrapper.deployed()
  console.log('🤺 deploy core/rarity_crafting_common_wrapper.sol', core_rarity_crafting_common_wrapper.address);

  const core_rarity_adventure_2 = await (await ethers.getContractFactory('contracts/core/rarity_adventure_2.sol:rarity_adventure_2', {
    libraries: {
      Attributes: library_attributes.address,
      Crafting: library_crafting.address,
      Proficiency: library_proficiency.address,
      Random: library_random.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Summoner: library_summoner.address
    }
  })).deploy()
  await core_rarity_adventure_2.deployed()
  console.log('🤺 deploy core/rarity_adventure_2.sol', core_rarity_adventure_2.address);



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [new RegExp(devAddresses.core_adventure_2, 'g')],
    to: [core_rarity_adventure_2.address]
  })
  await hre.run('compile')



  const core_crafting_mats_2 = await (await ethers.getContractFactory('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')).deploy()
  await core_crafting_mats_2.deployed()
  console.log('🤺 deploy core/rarity_crafting-materials-2.sol', core_crafting_mats_2.address);



  //////////////////////////////////////////////////
  console.log('\n🤖 update contract reference addresses and recompile')
  await replace.replaceInFile({
    files: 'contracts/**/*.sol',
    from: [
      new RegExp(devAddresses.core_crafting_mats_2, 'g'),
      new RegExp(devAddresses.codex_common_tools, 'g'),
      new RegExp(devAddresses.codex_weapons_masterwork, 'g'),
      new RegExp(devAddresses.codex_armor_masterwork, 'g'),
      new RegExp(devAddresses.codex_tools_masterwork, 'g')
    ],
    to: [
      core_crafting_mats_2.address,
      codex_items_tools.address,
      codex_items_weapons_masterwork.address,
      codex_items_armor_masterwork.address,
      codex_items_tools_masterwork.address
    ]
  })
  await hre.run('compile')

  const core_rarity_crafting_masterwork_uri = await (await ethers.getContractFactory('contracts/core/rarity_crafting_masterwork_uri.sol:MasterworkUri')).deploy()
  await core_rarity_crafting_masterwork_uri.deployed()
  console.log('📚 deploy core/core_rarity_crafting_masterwork_uri.sol', core_rarity_crafting_masterwork_uri.address);

  const core_rarity_crafting_masterwork = await (await ethers.getContractFactory('contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork', {
    libraries: {
      Crafting: library_crafting.address,
      CraftingSkills: library_crafting_skills.address,
      MasterworkUri: core_rarity_crafting_masterwork_uri.address,
      Rarity: library_rarity.address,
      Roll: library_roll.address,
      Skills: library_skills.address
    }
  })).deploy()
  await core_rarity_crafting_masterwork.deployed()
  console.log('🤺 deploy core/rarity_crafting_masterwork.sol', core_rarity_crafting_masterwork.address);

  await(await core_rarity_adventure_2.set_item_whitelist(
    core_rarity_crafting_common_wrapper.address,
    core_rarity_crafting_masterwork.address
  )).wait()
  console.log('🏳  set adventure 2 whitelist')

  await fs.writeFile('./deploy-addresses.json', JSON.stringify({
    codex_crafting_skills: codex_crafting_skills.address,
    codex_items_armor_2: codex_items_armor_2.address,
    codex_items_armor_masterwork: codex_items_armor_masterwork.address,
    codex_items_tools: codex_items_tools.address,
    codex_items_tools_masterwork: codex_items_tools_masterwork.address,
    codex_items_weapons_2: codex_items_weapons_2.address,
    codex_items_weapons_masterwork: codex_items_weapons_masterwork.address,
    library_rarity: library_rarity.address,
    library_skills: library_skills.address,
    library_attributes: library_attributes.address,
    library_crafting: library_crafting.address,
    library_feats: library_feats.address,
    library_proficiency: library_proficiency.address,
    core_rarity_crafting_skills: core_rarity_crafting_skills.address,
    library_crafting_skills: library_crafting_skills.address,
    library_random: library_random.address,
    library_roll: library_roll.address,
    library_combat: library_combat.address,
    library_summoner: library_summoner.address,
    core_rarity_crafting_common_wrapper: core_rarity_crafting_common_wrapper.address,
    core_rarity_adventure_2: core_rarity_adventure_2.address,
    core_crafting_mats_2: core_crafting_mats_2.address,
    core_rarity_crafting_masterwork_uri: core_rarity_crafting_masterwork_uri.address,
    core_rarity_crafting_masterwork: core_rarity_crafting_masterwork.address
  }, null, '\t'))
  console.log('📝 write deployed addresses to ./deploy-addresses.json')

  if(network.name === 'mainnet') {
    shell.exec('git commit -a -m "🚀 Deploy mainnet"')
  } else {
    shell.exec('git checkout contracts/*')
  }

  console.log('\n\n💥 deployed!!\n\n')
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error)
  console.log()
  console.log('reset contracts, git checkout contracts/*')
  shell.exec('git checkout contracts/*')
  console.log()
  console.log()
  process.exit(1)
})