import { MockContract, smock, FakeContract } from '@defi-wonderland/smock'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { parseEther } from 'ethers/lib/utils'

import {
  RarityBase,
  RarityBase__factory,
  Attributes,
  Attributes__factory,
  Armor,
  Armor__factory,
  Random,
  Random__factory,
  Combat,
  Combat__factory,
  Monster,
  Monster__factory,
  SkillCheck,
  SkillCheck__factory,
  Proficiency,
  Proficiency__factory,
  FeatCheck__factory,
  Weapon,
  Weapon__factory,
  FeatCheck,
  Rarity,
  RarityAttributes
} from '../../../typechain'

export interface IMockLibrary {
  rarityFakeCore: FakeContract<Rarity>
  rarityFakeAttributes: FakeContract<RarityAttributes>
  rarity: MockContract<RarityBase>
  attributes: MockContract<Attributes>
  armor: MockContract<Armor>
  random: MockContract<Random>
  combat: MockContract<Combat>
  monster: MockContract<Monster>
  skillCheck: MockContract<SkillCheck>
  featCheck: MockContract<FeatCheck>
  proficiency: MockContract<Proficiency>
  weapon: MockContract<Weapon>
}

export async function mockLibrary (): Promise<IMockLibrary> {
  const rarityFakeCore = await smock.fake<Rarity>('rarity', {
    address: '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb'
  })
  const rarityFakeAttributes = await smock.fake<RarityAttributes>(
    'rarity_attributes',
    { address: '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1' }
  )
  const weapon = await (await smock.mock<Weapon__factory>('Weapon')).deploy()
  const rarity = await (
    await smock.mock<RarityBase__factory>('RarityBase')
  ).deploy()
  const attributes = await (
    await smock.mock<Attributes__factory>('Attributes')
  ).deploy()
  const random = await (await smock.mock<Random__factory>('Random')).deploy()

  const monster = await (
    await smock.mock<Monster__factory>('Monster', {
      libraries: { Attributes: attributes.address, Random: random.address }
    })
  ).deploy()
  const skillCheck = await (
    await smock.mock<SkillCheck__factory>('SkillCheck', {
      libraries: { Random: random.address }
    })
  ).deploy()
  const featCheck = await (
    await smock.mock<FeatCheck__factory>('FeatCheck')
  ).deploy()
  const proficiency = await (
    await smock.mock<Proficiency__factory>('Proficiency', {
      libraries: {
        Weapon: weapon.address,
        FeatCheck: featCheck.address,
        RarityBase: rarity.address
      }
    })
  ).deploy()
  const combat = await (
    await smock.mock<Combat__factory>('Combat', {
      libraries: {
        Attributes: attributes.address,
        Random: random.address,
        Weapon: weapon.address,
        RarityBase: rarity.address
      }
    })
  ).deploy()
  const armor = await (
    await smock.mock<Armor__factory>('Armor', {
      libraries: {
        Attributes: attributes.address,
        Proficiency: proficiency.address
      }
    })
  ).deploy()
  return {
    rarityFakeCore,
    rarityFakeAttributes,
    rarity,
    attributes,
    armor,
    random,
    combat,
    monster,
    skillCheck,
    featCheck,
    proficiency,
    weapon
  }
}
