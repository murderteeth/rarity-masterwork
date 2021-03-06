import { ethers } from 'hardhat'
import {promises as fs} from 'fs'
import getContracts from './contracts'
import { armorType, baseType, toolType, weaponType } from '../../util/crafting';
import party from './party.json'

async function craft(contracts: any, crafter: any, baseType: number, itemType: number, tools: number) {
  let cost = await contracts.crafting.masterworkProjects.raw_materials_cost(baseType, itemType)
  if(!tools) cost = cost.add(await contracts.crafting.masterworkProjects.COMMON_ARTISANS_TOOLS_RENTAL())

  await contracts.gold.approve(crafter, await contracts.crafting.masterworkProjects.APPRENTICE(), cost)

  const startTx = await (await contracts.crafting.masterworkProjects.start(
    crafter, 
    baseType, 
    itemType, 
    tools
  )).wait()
  const token = startTx.events.filter((e: any) => e.event === 'Transfer').slice(-1)[0].args['tokenId']

  process.stdout.write('craft check ')
  while(1) {
    process.stdout.write('🔨')
    await contracts.mats2.approve(contracts.crafting.masterworkProjects.address, ethers.utils.parseEther('20'))
    const tx = await(await contracts.crafting.masterworkProjects.craft(token, ethers.utils.parseEther('20'))).wait()
    const craftEvent = tx.events.find((e: any) => e.event === 'Craft')
    if(craftEvent.args['m'].gte(craftEvent.args['n'])) {
      if(tools) await contracts.crafting.masterworkProjects.reclaim_tools(token)
      const claimTx = await(await contracts.crafting.masterworkItems.claim(token)).wait()
      const itemToken = claimTx.events.filter((e: any) => e.event === 'Transfer').slice(-1)[0].args['tokenId']
      process.stdout.write('\n')
      return itemToken
    }
  }
}

async function main() {
  const contracts = await getContracts()
  const signer = (await ethers.getSigners())[0]
  const salvage = await contracts.mats2.balanceOf(signer.address)
  console.log('barn salvage', ethers.utils.formatEther(salvage))

  const weaponsmith = party.crafters[0]
  await contracts.rarity.approve(contracts.crafting.masterworkProjects.address, weaponsmith)
  console.log('weaponsmith xp', ethers.utils.formatEther(await contracts.rarity.xp(weaponsmith)))
  console.log('weaponsmith gold', ethers.utils.formatEther(await contracts.gold.balanceOf(weaponsmith)))

  const armorsmith = party.crafters[1]
  await contracts.rarity.approve(contracts.crafting.masterworkProjects.address, armorsmith)
  console.log('armorsmith xp', ethers.utils.formatEther(await contracts.rarity.xp(armorsmith)))
  console.log('armorsmith gold', ethers.utils.formatEther(await contracts.gold.balanceOf(armorsmith)))

  console.log('⚒ craft masterwork artisan\'s tools')
  const artisansTools = (await craft(contracts, weaponsmith, baseType.tools, toolType.artisanTools, 0)).toString()

  console.log('⚔ craft masterwork longsword')
  await contracts.crafting.masterworkItems.approve(contracts.crafting.masterworkProjects.address, artisansTools)
  const longsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.longsword, artisansTools)).toString()

  console.log('⚔ craft masterwork greatsword')
  await contracts.crafting.masterworkItems.approve(contracts.crafting.masterworkProjects.address, artisansTools)
  const greatsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.greatsword, artisansTools)).toString()

  console.log('🛡 craft full plate armor')
  await contracts.crafting.masterworkItems.approve(contracts.crafting.masterworkProjects.address, artisansTools)
  const armor = (await craft(contracts, armorsmith, baseType.armor, armorType.fullPlate, artisansTools)).toString()

  console.log('🛡 craft big wood shield')
  await contracts.crafting.masterworkItems.approve(contracts.crafting.masterworkProjects.address, artisansTools)
  const shield = (await craft(contracts, armorsmith, baseType.armor, armorType.heavyWoodShield, artisansTools)).toString()

  console.log('write party.json')
  await fs.writeFile('./scripts/acceptance-test/party.json', JSON.stringify({
    ...party,
    equipment: {
      ...party.equipment,
      masterwork: {
        artisansTools,
        longsword,
        greatsword,
        armor,
        shield
      }
    }
  }, null, '\t'))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})