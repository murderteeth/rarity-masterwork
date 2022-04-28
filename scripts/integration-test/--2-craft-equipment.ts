import { ethers, network } from 'hardhat'
import {promises as fs} from 'fs'
import getContracts from './--contracts'
import { armorType, baseType, weaponType } from '../../test/util/crafting';
import party from './party.json'

async function jumpOneDay() {
  await network.provider.send('evm_increaseTime', [1 * 24 * 60 * 60])
  await network.provider.send('evm_mine')
}

async function craft(contracts: any, baseType: number, itemType: number) {
  const cost = await contracts.crafting.common.get_item_cost(baseType, itemType)
  await contracts.gold.approve(party.crafter, await contracts.crafting.common.SUMMMONER_ID(), cost)
  let craftchecks = 0
  while(1) {
    console.log('craftcheck', ++craftchecks)
    const tx = await(await contracts.crafting.common.craft(party.crafter, baseType, itemType, 0)).wait()
    const transferEvent = tx.events.find((e: any) => e.event === 'Transfer')
    if(transferEvent) {
      return transferEvent.args['tokenId']
    }
  }
}

async function main() {
  const contracts = await getContracts()
  await contracts.rarity.approve(contracts.crafting.common.address, party.crafter)
  await contracts.crafting.common.setApprovalForAll(contracts.crafting.commonWrapper.address, true)

  console.log('⚔ craft longsword')
  const longsword = (await craft(contracts, baseType.weapon, weaponType.longsword)).toString()
  await contracts.crafting.commonWrapper.approve(contracts.adventure2.address, longsword)

  console.log('⚔ craft greatsword')
  const greatsword = (await craft(contracts, baseType.weapon, weaponType.greatsword)).toString()
  await contracts.crafting.commonWrapper.approve(contracts.adventure2.address, greatsword)

  console.log('🛡 craft full plate armor')
  const armor = (await craft(contracts, baseType.armor, armorType.fullPlate)).toString()
  await contracts.crafting.commonWrapper.approve(contracts.adventure2.address, armor)

  console.log('🛡 craft big wood shield')
  const shield = (await craft(contracts, baseType.armor, armorType.heavyWoodShield)).toString()
  await contracts.crafting.commonWrapper.approve(contracts.adventure2.address, shield)

  console.log('write party.json')
  await fs.writeFile('./scripts/integration-test/party.json', JSON.stringify({
    ...party,
    equipment: {
      longsword,
      greatsword,
      armor,
      shield
    }
  }, null, '\t'))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})