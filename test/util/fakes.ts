import { FakeContract, smock } from '@defi-wonderland/smock'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { randomId } from '.'
import { Rarity, RarityAttributes, RarityCrafting, RarityCraftingWrapper, RarityFeats, RarityGold, RarityMasterwork, RaritySkills } from '../../typechain/core'
import { IRarityCodexBaseRandom2 } from '../../typechain/interfaces/codex'
import { armorType, baseType, weaponType } from './crafting'

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

export async function fakeCommonCraftingWrapper() {
  return await smock.fake<RarityCraftingWrapper>('contracts/core/rarity_crafting_common_wrapper.sol:rarity_crafting_wrapper')
}

export async function fakeMasterwork() {
  return await smock.fake<RarityMasterwork>('contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork')
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

export async function fakeGold() {
  const result = await smock.fake<RarityGold>('contracts/core/gold.sol:rarity_gold', {
    address: '0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2'
  })
  return result
}

export async function fakeRandom() {
  const result = await smock.fake<IRarityCodexBaseRandom2>('contracts/codex/codex-base-random-2.sol:codex', { 
    address: '0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18'
  })
  result.dn.returns(1)
  return result
}

export function fakeSummoner(rarity: FakeContract, signer: SignerWithAddress) {
  const summoner = randomId()
  rarity.ownerOf
  .whenCalledWith(summoner)
  .returns(signer.address)
  rarity.level
  .whenCalledWith(summoner)
  .returns(1)
  return summoner
}

export function fakeCraft(crafting: FakeContract, baseType: number, itemType: number, crafter: number, signer: SignerWithAddress) {
  const id = randomId()

  crafting.items
  .whenCalledWith(id)
  .returns([baseType, itemType, 0, crafter])

  crafting.ownerOf
  .whenCalledWith(id)
  .returns(signer.address)

  return id
}

export function fakeLongsword(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.weapon, weaponType.longsword, crafter, signer)
}

export function fakeGreatsword(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.weapon, weaponType.greatsword, crafter, signer)
}

export function fakeHeavyCrossbow(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.weapon, weaponType.heavyCrossbow, crafter, signer)
}

export function fakeLeatherArmor(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.armor, armorType.leather, crafter, signer)
}

export function fakeFullPlateArmor(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.armor, armorType.fullPlate, crafter, signer)
}

export function fakeHeavyWoodShield(crafting: FakeContract, crafter: number, signer: SignerWithAddress) {
  return fakeCraft(crafting, baseType.armor, armorType.heavyWoodShield, crafter, signer)
}