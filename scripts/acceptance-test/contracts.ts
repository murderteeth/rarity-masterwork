import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ethers, network } from 'hardhat'
import deployAddresses from '../../deploy-addresses.json'

export default async function getContracts(signer?: SignerWithAddress) {
  return {
    rarity: await ethers.getContractAt(
      'contracts/core/rarity.sol:rarity',
      '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb',
      signer
    ),
    gold: await ethers.getContractAt(
      'contracts/core/gold.sol:rarity_gold',
      '0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2',
      signer
    ),
    attributes: await ethers.getContractAt(
      'contracts/core/attributes.sol:rarity_attributes',
      '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1',
      signer
    ),
    skills: await ethers.getContractAt(
      'contracts/core/skills.sol:rarity_skills',
      '0x51C0B29A1d84611373BA301706c6B4b72283C80F',
      signer
    ),
    feats: await ethers.getContractAt(
      'contracts/core/feats.sol:rarity_feats', 
      '0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a',
      signer
    ),
    crafting: {
      common: await ethers.getContractAt(
        'contracts/core/rarity_crafting_common.sol:rarity_crafting', 
        '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC',
        signer
      ),
      commonWrapper: await ethers.getContractAt(
        'contracts/core/rarity_crafting_common_wrapper.sol:rarity_crafting_wrapper', 
        deployAddresses.core_rarity_crafting_common_wrapper,
        signer
      ),
      masterwork: await ethers.getContractAt(
        'contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork', 
        deployAddresses.core_rarity_crafting_masterwork,
        signer
      )
    },
    adventure2: await ethers.getContractAt(
      'contracts/core/rarity_adventure-2.sol:rarity_adventure_2', 
      deployAddresses.core_rarity_adventure_2,
      signer
    ),
    mats2: await ethers.getContractAt(
      'contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2',
      deployAddresses.core_crafting_mats_2,
      signer
    ),
    craftingSkills: await ethers.getContractAt(
      'contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills',
      deployAddresses.core_rarity_crafting_skills,
      signer
    ),
    library: {
      random: await ethers.getContractAt(
        'contracts/library/Random.sol:Random',
        '0x1c85638e118b37167e9298c2268758e058DdfDA0',
        signer
      )
    }
  }  
}