import { MockContract, smock, FakeContract } from '@defi-wonderland/smock'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { parseEther } from 'ethers/lib/utils'
import { skills as skillsenum, skillsArray } from './skills'
import { 
  CodexMasterworkWeapons, 
  CodexMasterworkWeapons__factory, 
  CodexBaseRandomMockable,
  CodexBaseRandomMockable__factory,
  Rarity, 
  Rarity__factory,
  RarityAttributes, 
  RarityAttributes__factory, 
  RarityCrafting, 
  RarityCrafting__factory, 
  RarityCraftingMaterials, 
  RarityCraftingMaterials__factory, 
  RarityGold, 
  RarityGold__factory, 
  RarityMasterworkItem, 
  RarityMasterworkItem__factory, 
  RarityMasterworkProject, 
  RarityMasterworkProject__factory, 
  RaritySkills, 
  RaritySkills__factory,
  RarityCommonTools,
  RarityCommonTools__factory,
  RarityKoboldBarn,
  RarityKoboldBarn__factory,
  SkillCheck__factory,
  Random__factory,
  Monster__factory,
  Combat__factory,
  Auth__factory,
  Armor__factory,
  Attributes__factory
} from '../../typechain'

export interface IMockRarityContracts {
  core: MockContract<Rarity>,
  fakeCore: FakeContract<Rarity>,
  random: MockContract<CodexBaseRandomMockable>,
  attributes: MockContract<RarityAttributes>,
  gold: MockContract<RarityGold>,
  skills: MockContract<RaritySkills>,
  mats: MockContract<RarityCraftingMaterials>,
  crafting: MockContract<RarityCrafting>
}

export interface IMockMasterworkContracts {
  codex: {
    weapons: MockContract<CodexMasterworkWeapons>
  },
  projects: MockContract<RarityMasterworkProject>,
  items: MockContract<RarityMasterworkItem>,
  commonTools: MockContract<RarityCommonTools>,
  barn: MockContract<RarityKoboldBarn>
}

export async function mockMasterwork(rarity: IMockRarityContracts) : Promise<IMockMasterworkContracts> {
  const weapons = await (await smock.mock<CodexMasterworkWeapons__factory>('CodexMasterworkWeapons')).deploy()
  const projects = await (await smock.mock<RarityMasterworkProject__factory>('RarityMasterworkProject')).deploy()
  await projects.setVariable('rm', rarity.core.address)
  await projects.setVariable('rarity', rarity.core.address)
  await projects.setVariable('attributes', rarity.attributes.address)
  await projects.setVariable('gold', rarity.gold.address)
  await projects.setVariable('skills', rarity.skills.address)
  await projects.setVariable('commonCrafting', rarity.crafting.address)
  await projects.setVariable('masterworkWeaponsCodex', weapons.address)
  await rarity.core.setVariable('_owners', { [(await projects.APPRENTICE()).toNumber()]: projects.address })

  const rarityAuth = await (await smock.mock<Auth__factory>('Auth')).deploy()
  const rarityAttributes = await (await smock.mock<Attributes__factory>('Attributes')).deploy()
  const rarityArmor = await (await smock.mock<Armor__factory>('Armor', {
    libraries: {
      Attributes: rarityAttributes.address
    }
  })).deploy()

  const items = await (await smock.mock<RarityMasterworkItem__factory>('RarityMasterworkItem', {
    libraries: {
      Auth: rarityAuth.address
    }
  }
  )).deploy()
  await items.setVariable('projects', projects.address)
  const commonTools = await (await smock.mock<RarityCommonTools__factory>('RarityCommonTools', {
    libraries: {
      Auth: rarityAuth.address
    }
  })).deploy()
  await commonTools.setVariable('commonCrafting', rarity.crafting.address)

  const rarityRandom = await (await smock.mock<Random__factory>('Random')).deploy()
  const rarityCombat = await (await smock.mock<Combat__factory>('Combat', {
    libraries: {
      Attributes: rarityAttributes.address,
      Random: rarityRandom.address
    }
  })).deploy()

  const rarityMonster = await (await smock.mock<Monster__factory>('Monster', {
    libraries: {
      Random: rarityRandom.address
    }
  })).deploy()

  const raritySkillCheck = await (await smock.mock<SkillCheck__factory>('SkillCheck', {
    libraries: {
      Random: rarityRandom.address
    }
  })).deploy()
  const barn = await (await smock.mock<RarityKoboldBarn__factory>('RarityKoboldBarn', {
    libraries: {
      SkillCheck: raritySkillCheck.address,
      Monster: rarityMonster.address,
      Combat: rarityCombat.address,
      Auth: rarityAuth.address,
      Armor: rarityArmor.address
      // RarityRandom: rarityRandom.address
    }})).deploy(items.address)

  return { codex: { weapons }, projects, items, commonTools, barn }
}

export async function mockRarity() : Promise<IMockRarityContracts> {
  const core = await (await smock.mock<Rarity__factory>('rarity')).deploy()
  await core.setVariable('next_summoner', 1)
  const random = await (await smock.mock<CodexBaseRandomMockable__factory>('codex_base_random_mockable')).deploy()
  const attributes = await (await smock.mock<RarityAttributes__factory>('rarity_attributes')).deploy()
  await attributes.setVariable('rm', core.address)
  const gold = await (await smock.mock<RarityGold__factory>('rarity_gold')).deploy()
  await gold.setVariable('rm', core.address)
  const skills = await (await smock.mock<RaritySkills__factory>('rarity_skills')).deploy()
  await skills.setVariable('rm', core.address)
  await skills.setVariable('_attr', attributes.address)
  const mats = await (await smock.mock<RarityCraftingMaterials__factory>('rarity_crafting_materials')).deploy()
  await mats.setVariable('rm', core.address)
  await mats.setVariable('_attr', attributes.address)
  const crafting = await (await smock.mock<RarityCrafting__factory>('rarity_crafting')).deploy()
  await crafting.setVariable('_rm', core.address)
  await crafting.setVariable('_attr', attributes.address)
  await crafting.setVariable('_craft_i', mats.address)
  await crafting.setVariable('_gold', gold.address)
  await crafting.setVariable('_skills', skills.address)
  const fakeCore = await smock.fake<Rarity>('rarity', {address: "0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb"})
  return { core, fakeCore, attributes, gold, skills, mats, crafting }
}

export async function mockCrafter(rarity: IMockRarityContracts, signer: SignerWithAddress) {
  const summoner = await rarity.core.next_summoner()
  await rarity.core.setVariable('_balances', { [signer.address]: 1 })
  await rarity.core.setVariable('_owners', { [summoner.toNumber()]: signer.address })
  await rarity.core.setVariable('_owners', { [(await rarity.crafting.SUMMMONER_ID()).toNumber()]: rarity.crafting.address })
  await rarity.core.setVariable('class', { [summoner.toNumber()]: 11 })
  await rarity.core.setVariable('level', { [summoner.toNumber()]: 5 })
  await rarity.core.setVariable('xp', { [summoner.toNumber()]: parseEther('10000') })
  await rarity.core.setVariable('next_summoner', summoner.add(1))
  await rarity.gold.setVariable('balanceOf', { [summoner.toNumber()]: parseEther('10000') })
  await rarity.attributes.setVariable('ability_scores', { [summoner.toNumber()]: {
    strength: 8,
    dexterity: 8,
    constitution: 10,
    intelligence: 19,
    wisdom: 16,
    charisma: 8 }})
  await rarity.attributes.setVariable('level_points_spent', { [summoner.toNumber()]: 32 })
  await rarity.attributes.setVariable('character_created', { [summoner.toNumber()]: true })
  await rarity.skills.setVariable('skills', { [summoner.toNumber()]: skillsArray(
    { index: skillsenum.craft, points: 8 }) })
  await rarity.mats.setVariable('balanceOf', { [summoner.toNumber()]: 1_000_000 })
  return summoner
}

export async function mockCommonItem(base_type: number, item_type: number, crafter: number, rarity: IMockRarityContracts, signer: SignerWithAddress) {
  const item = await rarity.crafting.next_item()
  const balance = await rarity.crafting.balanceOf(signer.address)
  await rarity.crafting.setVariable('items', { [item.toNumber()]: { base_type, item_type, crafted: 0, crafter }})
  await rarity.crafting.setVariable('_owners', { [item.toNumber()]: signer.address })
  await rarity.crafting.setVariable('_balances', { [signer.address]: balance.add(1) })
  await rarity.crafting.setVariable('next_item', item.add(1))
  return item
}

export async function mockMasterworkProject(baseType: number, itemType: number, crafter: number, masterwork: IMockMasterworkContracts) {
  const project = await masterwork.projects.nextToken()
  const balance = await masterwork.projects.balanceOf(crafter)
  await masterwork.projects.setVariable('projects', { [project.toNumber()]: { baseType, itemType, check: 0, xp: 0, started: 1, completed: 0 }})
  await masterwork.projects.setVariable('_owners', { [project.toNumber()]: crafter })
  await masterwork.projects.setVariable('_balances', { [crafter]: balance.add(1) })
  await masterwork.projects.setVariable('nextToken', project.add(1))
  return project
}

export async function useRandomMock(context: Mocha.Context, contract: MockContract, contractVariable: string, mockResult: number, fn: () => {}) {
  await context.rarity.random.setVariable('__mock_enabled', true)
  await context.rarity.random.setVariable('__mock_result', mockResult)
  await contract.setVariable(contractVariable, context.rarity.random.address)
  await fn()
  await context.rarity.random.setVariable('__mock_enabled', false)
  await context.rarity.random.setVariable('__mock_result', 0)
  await contract.setVariable(contractVariable, '0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4')
}