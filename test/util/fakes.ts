import { smock } from '@defi-wonderland/smock'
import { Rarity, RarityAttributes, RarityCrafting, RarityFeats, RaritySkills } from '../../typechain/core'
import { IRarityCodexBaseRandom2 } from '../../typechain/interfaces/codex'

export async function fakeRarity() {
  return await smock.fake<Rarity>('contracts/core/rarity.sol:rarity', { 
    address: '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb' 
  })
}

export async function fakeCommonCrafting() {
  return await smock.fake<RarityCrafting>('contracts/core/rarity_crafting_common.sol:rarity_crafting', { 
    address: '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC'
  })
}

export async function fakeAttributes() {
  const result = await smock.fake<RarityAttributes>('contracts/core/attributes.sol:rarity_attributes', { 
    address: '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1'
  })
  result.ability_scores
  .returns([0, 0, 0, 0, 0, 0])
  return result
}

export async function fakeSkills() {
  const result = await smock.fake<RaritySkills>('contracts/core/skills.sol:rarity_skills', {
    address: '0x51C0B29A1d84611373BA301706c6B4b72283C80F'
  })
  result.get_skills
  .returns(Array(36).fill(0))
  return result
}

export async function fakeFeats() {
  const result = await smock.fake<RarityFeats>('contracts/core/feats.sol:rarity_feats', {
    address: '0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a'
  })
  result.get_feats
  .returns(Array(100).fill(false))
  return result
}

export async function fakeRandom() {
  const result = await smock.fake<IRarityCodexBaseRandom2>('contracts/codex/codex-base-random-2.sol:codex', { 
    address: '0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18'
  })
  result.dn.returns(1)
  return result
}