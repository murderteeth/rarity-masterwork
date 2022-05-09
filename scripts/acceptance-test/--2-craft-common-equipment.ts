import {promises as fs} from 'fs'
import getContracts from './contracts'
import { armorType, baseType, weaponType } from '../../util/crafting';
import party from './party.json'

async function craft(contracts: any, baseType: number, itemType: number) {
  const cost = await contracts.crafting.common.get_item_cost(baseType, itemType)
  await contracts.gold.approve(party.crafters[0], await contracts.crafting.common.SUMMMONER_ID(), cost)
  process.stdout.write('craft check ')
  while(1) {
    process.stdout.write('🔨')
    const tx = await(await contracts.crafting.common.craft(party.crafters[0], baseType, itemType, 0)).wait()
    const transferEvent = tx.events.find((e: any) => e.event === 'Transfer')
    if(transferEvent) {
      process.stdout.write('\n')
      return transferEvent.args['tokenId']
    }
  }
}

async function main() {
  const contracts = await getContracts()
  await contracts.rarity.approve(contracts.crafting.common.address, party.crafters[0])

  console.log('⚔ craft longsword')
  const longsword = (await craft(contracts, baseType.weapon, weaponType.longsword)).toString()

  console.log('⚔ craft greatsword')
  const greatsword = (await craft(contracts, baseType.weapon, weaponType.greatsword)).toString()

  console.log('🛡 craft full plate armor')
  const armor = (await craft(contracts, baseType.armor, armorType.fullPlate)).toString()

  console.log('🛡 craft big wood shield')
  const shield = (await craft(contracts, baseType.armor, armorType.heavyWoodShield)).toString()

  console.log('write party.json')
  await fs.writeFile('./scripts/acceptance-test/party.json', JSON.stringify({
    ...party,
    equipment: {
      common: {
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