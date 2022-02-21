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
  Attributes__factory,
  CodexMasterworkTools__factory,
  CodexCommonTools__factory,
  FeatCheck,
  Auth,
  Attributes,
  Armor,
  Random,
  Combat,
  Monster,
  SkillCheck,
  CodexCommonTools,
  CodexMasterworkTools,
  FeatCheck__factory,
  RarityKoboldSalvage,
  RarityKoboldSalvage__factory
} from '../../typechain'

export interface IMockLibrary {
  auth: MockContract<Auth>,
  attributes: MockContract<Attributes>,
  armor: MockContract<Armor>,
  random: MockContract<Random>,
  combat: MockContract<Combat>,
  monster: MockContract<Monster>,
  skillCheck: MockContract<SkillCheck>,
  featCheck: MockContract<FeatCheck>
}

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
    weapons: MockContract<CodexMasterworkWeapons>,
    commonTools: MockContract<CodexCommonTools>,
    tools: MockContract<CodexMasterworkTools>
  },
  projects: MockContract<RarityMasterworkProject>,
  items: MockContract<RarityMasterworkItem>,
  commonTools: MockContract<RarityCommonTools>,
  barn: MockContract<RarityKoboldBarn>,
  salvage: MockContract<RarityKoboldSalvage>
}

export async function mockLibrary() : Promise<IMockLibrary> {
  const auth = await (await smock.mock<Auth__factory>('Auth')).deploy()
  const attributes = await (await smock.mock<Attributes__factory>('Attributes')).deploy()
  const armor = await (await smock.mock<Armor__factory>('Armor', { 
    libraries: { Attributes: attributes.address } 
  })).deploy()
  const random = await (await smock.mock<Random__factory>('Random')).deploy()
  const combat = await (await smock.mock<Combat__factory>('Combat', {
    libraries: { Attributes: attributes.address, Random: random.address }
  })).deploy()
  const monster = await (await smock.mock<Monster__factory>('Monster', {
    libraries: { Attributes: attributes.address, Random: random.address }
  })).deploy()
  const skillCheck = await (await smock.mock<SkillCheck__factory>('SkillCheck', {
    libraries: { Random: random.address }
  })).deploy()
  const featCheck = await (await smock.mock<FeatCheck__factory>('FeatCheck')).deploy()
  return { auth, attributes, armor, random, combat, monster, skillCheck, featCheck }
}

export async function mockMasterwork(library: IMockLibrary, rarity: IMockRarityContracts) : Promise<IMockMasterworkContracts> {
  const weaponsCodex = await (await smock.mock<CodexMasterworkWeapons__factory>('CodexMasterworkWeapons')).deploy()
  const projects = await (await smock.mock<RarityMasterworkProject__factory>('RarityMasterworkProject')).deploy()
  await projects.setVariable('rm', rarity.core.address)
  await projects.setVariable('rarity', rarity.core.address)
  await projects.setVariable('attributes', rarity.attributes.address)
  await projects.setVariable('gold', rarity.gold.address)
  await projects.setVariable('skills', rarity.skills.address)
  await projects.setVariable('masterworkWeaponsCodex', weaponsCodex.address)
  await rarity.core.setVariable('_owners', { [(await projects.APPRENTICE()).toNumber()]: projects.address })
  const toolsCodex = await (await smock.mock<CodexMasterworkTools__factory>('CodexMasterworkTools')).deploy()
  const items = await (await smock.mock<RarityMasterworkItem__factory>('RarityMasterworkItem')).deploy()
  await items.setVariable('rarity', rarity.core.address)
  await items.setVariable('projects', projects.address)
  await items.setVariable('toolsCodex', toolsCodex.address)
  const commonToolsCodex = await (await smock.mock<CodexCommonTools__factory>('CodexCommonTools')).deploy()
  const commonTools = await (await smock.mock<RarityCommonTools__factory>('RarityCommonTools')).deploy()
  await commonTools.setVariable('rarity', rarity.core.address)
  await commonTools.setVariable('commonCrafting', rarity.crafting.address)
  await commonTools.setVariable('toolsCodex', commonToolsCodex.address)
  const barn = await (await smock.mock<RarityKoboldBarn__factory>('RarityKoboldBarn', {
    libraries: {
      SkillCheck: library.skillCheck.address,
      Monster: library.monster.address,
      Combat: library.combat.address,
      Auth: library.auth.address,
      Armor: library.armor.address,
      FeatCheck: library.featCheck.address
      // RarityRandom: rarityRandom.address
    }
  })).deploy(items.address)
  const salvage = await (await smock.mock<RarityKoboldSalvage__factory>('RarityKoboldSalvage', {
    libraries: {
      Auth: library.auth.address
    }
  })).deploy(barn.address)
  return { codex: { 
    weapons: weaponsCodex, 
    commonTools: commonToolsCodex,
    tools: toolsCodex
  }, projects, items, commonTools, barn, salvage }
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
  return { core, fakeCore, random, attributes, gold, skills, mats, crafting }
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

export async function mockMasterworkProject(crafter: number, baseType: number, itemType: number, tools: number, toolsContract: string, masterwork: IMockMasterworkContracts) {
  const project = await masterwork.projects.nextToken()
  const balance = await masterwork.projects.balanceOf(crafter)
  await masterwork.projects.setVariable('projects', { [project.toNumber()]: { 
    baseType, itemType, tools, toolsContract, check: 0, xp: 0, started: 1, completed: 0 }})
  await masterwork.projects.setVariable('_owners', { [project.toNumber()]: crafter })
  await masterwork.projects.setVariable('_balances', { [crafter]: balance.add(1) })
  await masterwork.projects.setVariable('nextToken', project.add(1))
  return project
}

export async function mockCommonTools(crafter: number, masterwork: IMockMasterworkContracts, signer: SignerWithAddress) {
  const tools = await masterwork.commonTools.nextToken()
  const balance = await masterwork.commonTools.balanceOf(signer.address)
  await masterwork.commonTools.setVariable('items', { [tools.toNumber()]: { 
    base_type: 4, item_type: 2, crafted: 0, crafter }})
  await masterwork.commonTools.setVariable('_owners', { [tools.toNumber()]: signer.address })
  await masterwork.commonTools.setVariable('_balances', { [signer.address]: balance.add(1) })
  await masterwork.commonTools.setVariable('nextToken', tools.add(1))
  return tools
}

export async function mockMasterworkTools(crafter: number, masterwork: IMockMasterworkContracts, signer: SignerWithAddress) {
  const tools = await masterwork.items.nextToken()
  const balance = await masterwork.items.balanceOf(signer.address)
  await masterwork.items.setVariable('items', { [tools.toNumber()]: {
    baseType: 4, itemType: 2, crafted: 0, crafter }})
  await masterwork.items.setVariable('_owners', { [tools.toNumber()]: signer.address })
  await masterwork.items.setVariable('_balances', { [signer.address]: balance.add(1) })
  await masterwork.items.setVariable('nextToken', tools.add(1))
  return tools
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