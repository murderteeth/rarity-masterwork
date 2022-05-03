import { ethers } from 'hardhat'
import {promises as fs} from 'fs'
import getContracts from './contracts'
import { armorType, baseType, toolType, weaponType } from '../../test/util/crafting';
import party from './party.json'

function logUri(message: string, tokenUri: string) {
  const tokenJson = JSON.parse(Buffer.from(tokenUri.split(',')[1], "base64").toString());
  const tokenSvg = Buffer.from(tokenJson.image.split(',')[1], "base64").toString();
  console.log(message, tokenJson.image)
}

async function craft(contracts: any, crafter: any, baseType: number, itemType: number, tools: number) {
  let cost = await contracts.crafting.masterwork.raw_materials_cost(baseType, itemType)
  if(!tools) cost = cost.add(await contracts.crafting.masterwork.COMMON_ARTISANS_TOOLS_RENTAL())

  await contracts.gold.approve(crafter, await contracts.crafting.masterwork.APPRENTICE(), cost)

  const startTx = await (await contracts.crafting.masterwork.start(
    crafter, 
    baseType, 
    itemType, 
    tools
  )).wait()
  const token = startTx.events.filter((e: any) => e.event === 'Transfer').slice(-1)[0].args['tokenId']
  await logUri('project start', await contracts.crafting.masterwork.tokenURI(token))

  process.stdout.write('craft check ')
  while(1) {
    process.stdout.write('🔨')
    await contracts.mats2.approve(contracts.crafting.masterwork.address, ethers.utils.parseEther('20'))
    const tx = await(await contracts.crafting.masterwork.craft(token, crafter, ethers.utils.parseEther('20'))).wait()
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
  console.log('barn salvage', ethers.utils.formatEther(salvage))

  const weaponsmith = party.crafters[0]
  await contracts.rarity.approve(contracts.crafting.masterwork.address, weaponsmith)
  console.log('weaponsmith xp', ethers.utils.formatEther(await contracts.rarity.xp(weaponsmith)))
  console.log('weaponsmith gold', ethers.utils.formatEther(await contracts.gold.balanceOf(weaponsmith)))

  const armorsmith = party.crafters[1]
  await contracts.rarity.approve(contracts.crafting.masterwork.address, armorsmith)
  console.log('armorsmith xp', ethers.utils.formatEther(await contracts.rarity.xp(armorsmith)))
  console.log('armorsmith gold', ethers.utils.formatEther(await contracts.gold.balanceOf(armorsmith)))

  console.log('⚒ craft masterwork artisan\'s tools')
  const artisansTools = (await craft(contracts, weaponsmith, baseType.tools, toolType.artisanTools, 0)).toString()
  await logUri('artisansTools', await contracts.crafting.masterwork.tokenURI(artisansTools))

  console.log('⚒ craft thieve\'s tools')
  await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  const thievesTools = (await craft(contracts, weaponsmith, baseType.tools, toolType.thievesTools, artisansTools)).toString()
  await logUri('thievesTools', await contracts.crafting.masterwork.tokenURI(thievesTools))

  console.log('⚔ craft masterwork longsword')
  await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  const longsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.longsword, artisansTools)).toString()
  await logUri('longsword', await contracts.crafting.masterwork.tokenURI(longsword))



  // console.log('⚔ craft masterwork greatsword')
  // await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  // const greatsword = (await craft(contracts, weaponsmith, baseType.weapon, weaponType.greatsword, artisansTools)).toString()

  // console.log('🛡 craft full plate armor')
  // await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  // const armor = (await craft(contracts, armorsmith, baseType.armor, armorType.fullPlate, artisansTools)).toString()
  // await logUri('armor', await contracts.crafting.masterwork.tokenURI(armor))

  console.log('🛡 craft leather armor')
  await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  const leatherArmor = (await craft(contracts, armorsmith, baseType.armor, armorType.leather, artisansTools)).toString()
  await logUri('leatherArmor', await contracts.crafting.masterwork.tokenURI(leatherArmor))

  // console.log('🛡 craft big wood shield')
  // await contracts.crafting.masterwork.approve(contracts.crafting.masterwork.address, artisansTools)
  // const shield = (await craft(contracts, armorsmith, baseType.armor, armorType.heavyWoodShield, artisansTools)).toString()

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})