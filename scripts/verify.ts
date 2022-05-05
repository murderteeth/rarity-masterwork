import hre, { ethers, network } from 'hardhat'
import deployAddresses from '../deploy-addresses.json'

async function main() {
  if(network.name !== 'mainnet') throw('not mainnet!')
  const signers = await ethers.getSigners()
  const signer = signers[0]
  console.log('signer', signer.address, ethers.utils.formatEther(await signer.getBalance()), 'FTM')

  // const entries = Object.entries(deployAddresses)
  // for(let i = 0; i < entries.length; i++) {
  //   const [contract, address] = entries[i]
  //   console.log('✔ verify', contract, '@', address)
  //   await hre.run("verify:verify", { address });
  // }
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error)
  process.exit(1)
})