import hre, { ethers, network } from 'hardhat'
import {promises as fs} from 'fs'
import mainnetAddresses from '../addresses.mainnet.json'

async function main() {
  if(network.name !== 'mainnet') throw('not mainnet!')
  const signers = await ethers.getSigners()
  const signer = signers[0]
  console.log('signer', signer.address, ethers.utils.formatEther(await signer.getBalance()), 'FTM')

  const deployments = mainnetAddresses as { [key: string]: any }
  const keys = Object.keys(mainnetAddresses)
  for(let i = 0; i < keys.length; i++) {
    const key = keys[i]
    const deployment = deployments[key]
    if(!deployment.verified) {
      console.log('verify ', deployment.contract, '@', deployment.address)
      try {
        await hre.run("verify:verify", { 
          contract: deployment.contract, 
          address: deployment.address 
        })
        deployment.verified = true
        await fs.writeFile('./addresses.mainnet.json', JSON.stringify(deployments, null, '\t'))
      } catch(error) {
        if((error as any).toString().includes('Already Verified')) {
          deployment.verified = true
          await fs.writeFile('./addresses.mainnet.json', JSON.stringify(deployments, null, '\t'))
        } else {
          throw error
        }
      }
    }
  }
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error)
  process.exit(1)
})