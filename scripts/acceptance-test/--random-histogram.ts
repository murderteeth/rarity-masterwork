import getContracts from './contracts'
import { jumpOneMinute } from './jump'

async function main() {
  const contracts = await getContracts()

  {
    const sample = 1000
    console.log('\n🎲 D20 Histogram, varied blocktime,', sample, 'samples')
  
    const seed = 1
    const token = 1
    const d20Rolls = Array(20).fill(0)
    for(let i = 0; i < sample; i ++) {
      const roll = await contracts.library.random['dn(uint256,uint256,uint8,uint8)'](seed, token, 1, 20)
      await jumpOneMinute()
      d20Rolls[roll - 1]++
    }
  
    const maxHeight = 10
    const rollsMax = Math.max(...d20Rolls)
    const scale = rollsMax / maxHeight
    d20Rolls.forEach((rolls: any, index: any) => {
      console.log('roll', String(index + 1).padStart(3, ' '), '', '*'.repeat(rolls/scale))
    })
  }

  {
    const sample = 1000
    console.log('\n🎲 D20 Histogram, varied seed,', sample, 'samples')
  
    const token = 1
    const d20Rolls = Array(20).fill(0)
    for(let i = 0; i < sample; i ++) {
      const seed = i + 1
      const roll = await contracts.library.random['dn(uint256,uint256,uint8,uint8)'](seed, token, 1, 20)
      await jumpOneMinute()
      d20Rolls[roll - 1]++
    }

    const maxHeight = 10
    const rollsMax = Math.max(...d20Rolls)
    const scale = rollsMax / maxHeight
    d20Rolls.forEach((rolls: any, index: any) => {
      console.log('roll', String(index + 1).padStart(3, ' '), '', '*'.repeat(rolls/scale))
    })
  }

  console.log()
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})