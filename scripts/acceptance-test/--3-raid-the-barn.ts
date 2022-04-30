import { winRates } from './adventure'
import getContracts from './contracts'
import party from './party.json'

async function main() {
  const contracts = await getContracts()
  await winRates(contracts, party.equipment.common, contracts.crafting.commonWrapper.address)
  // await logAdventures(contracts, party.equipment.common, contracts.crafting.commonWrapper.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})