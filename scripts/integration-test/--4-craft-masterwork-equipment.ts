import { ethers, network } from 'hardhat'
import {promises as fs} from 'fs'
import getContracts from './contracts'
import { armorType, baseType, toolType, weaponType } from '../../test/util/crafting';
import party from './party.json'

async function jumpOneDay() {
  await network.provider.send('evm_increaseTime', [1 * 24 * 60 * 60])
  await network.provider.send('evm_mine')
}

async function craft(contracts: any, crafter: any, baseType: number, itemType: number, tools: number) {
  let cost = await contracts.crafting.masterwork.raw_materials_cost(baseType, itemType)
  if(!tools) cost = cost.add(await contracts.crafting.masterwork.COMMON_ARTISANS_TOOLS_RENTAL())

  await contracts.gold.approve(crafter, await contracts.crafting.masterwork.APPRENTICE(), cost)

  const startTx = await (await contracts.crafting.masterwork.start(
    crafter, 
    baseType, 
    itemType, 
    tools, 
    tools ? contracts.crafting.masterwork.address : ethers.constants.AddressZero
  )).wait()
  const token = startTx.events.filter((e: any) => e.event === 'Transfer').slice(-1)[0].args['tokenId']

  process.stdout.write('craft check ')
  while(1) {
    process.stdout.write('🔨')
    const tx = await(await contracts.crafting.masterwork.craft(token, crafter, 0)).wait()
    const craftEvent = tx.events.find((e: any) => e.event === 'Craft')
    if(craftEvent.args['m'].gte(craftEvent.args['n'])) {
      await contracts.crafting.masterwork.complete(token, crafter)
      process.stdout.write('\n')
      return token
    }
  }
}

async function main() {
  const contracts = await getContracts()
  const signer = (await ethers.getSigners())[0]
  const salvage = await contracts.mats2.balanceOf(signer.address)
  console.log('party barn salvage', ethers.utils.formatEther(salvage))

  const weaponsmith = party.crafters[0]
  await contracts.rarity.approve(contracts.crafting.masterwork.address, weaponsmith)
  console.log('weaponsmith xp', ethers.utils.formatEther(await contracts.rarity.xp(weaponsmith)))
  console.log('weaponsmith gold', ethers.utils.formatEther(await contracts.gold.balanceOf(weaponsmith)))

  console.log('⚒ craft masterwork artisan\'s tools')
  const artisansTools = (await craft(contracts, weaponsmith, baseType.tools, toolType.artisanTools, 0)).toString()

  console.log('⚔ craft masterwork longsword')
  await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  const longsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.longsword, artisansTools)).toString()

  console.log('⚔ craft masterwork greatsword')
  await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  const greatsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.greatsword, artisansTools)).toString()

  console.log('write party.json')
  await fs.writeFile('./scripts/integration-test/party.json', JSON.stringify({
    ...party,
    equipment: {
      ...party.equipment,
      masterwork: {
        artisansTools,
        longsword,
        greatsword
      }
    }
  }, null, '\t'))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})