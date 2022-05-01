import { winRates } from './adventure'
import getContracts from './contracts'
import party from './party.json'

async function main() {
  const contracts = await getContracts()

  const equipmentApprovals = async function() {
    await contracts.crafting.masterwork.approve(contracts.adventure2.address, party.equipment.masterwork.longsword)
    await contracts.crafting.masterwork.approve(contracts.adventure2.address, party.equipment.masterwork.greatsword)
    await contracts.crafting.masterwork.approve(contracts.adventure2.address, party.equipment.masterwork.armor)
    await contracts.crafting.masterwork.approve(contracts.adventure2.address, party.equipment.masterwork.shield)
  }

  await winRates(contracts, equipmentApprovals, party.equipment.masterwork, contracts.crafting.masterwork.address)
  // await logAdventures(contracts, equipmentApprovals, party.equipment.masterwork, contracts.crafting.masterwork.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})