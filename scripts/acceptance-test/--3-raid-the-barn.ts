import { winRates } from './adventure'
import getContracts from './contracts'
import party from './party.json'

async function main() {
  const contracts = await getContracts()

  const equipmentApprovals = async function() {
    await contracts.crafting.common.approve(contracts.equipment2.address, party.equipment.common.longsword)
    await contracts.crafting.common.approve(contracts.equipment2.address, party.equipment.common.greatsword)
    await contracts.crafting.common.approve(contracts.equipment2.address, party.equipment.common.armor)
    await contracts.crafting.common.approve(contracts.equipment2.address, party.equipment.common.shield)
  }

  await winRates(contracts, equipmentApprovals, party.equipment.common, contracts.crafting.common.address)
  // await logAdventures(contracts, equipmentApprovals, party.equipment.common, contracts.crafting.common.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})