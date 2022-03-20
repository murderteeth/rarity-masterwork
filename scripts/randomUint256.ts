import { BigNumber } from "ethers";

async function main() {
  const hex = Array(16).fill('')
  .map(() => Math.round(Math.random() * 0xF).toString(16))
  .join('')
  const rando = BigNumber.from(`0x${hex}`)
  console.log('rando', rando.toString())
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})