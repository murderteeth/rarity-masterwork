import hre, { ethers, network } from 'hardhat'
import {promises as fs} from 'fs'
import mainnetAddresses from '../addresses.mainnet.json'

async function main() {
  if(network.name !== 'mainnet') throw('not mainnet!')
  const signers = await ethers.getSigners()
  const signer = signers[0]
  console.log('signer', signer.address, ethers.utils.formatEther(await signer.getBalance()), 'FTM')

  const deployments = Object.values(mainnetAddresses)
  for(let i = 0; i < deployments.length; i++) {
    const deployment = deployments[i]
    if(!deployment.verified) {
      console.log('verify ', deployment.contract, '@', deployment.address)
      await hre.run("verify:verify", { 
        contract: deployment.contract, 
        address: deployment.address 
      })
      deployment.verified = true
      await fs.writeFile('./addresses.mainnet.json', JSON.stringify(deployments, null, '\t'))
    }
  }
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error)
  process.exit(1)
})