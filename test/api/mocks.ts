import { MockContract, smock } from '@defi-wonderland/smock'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { parseEther } from 'ethers/lib/utils'
import { CodexMasterworkWeapons, CodexMasterworkWeapons__factory, Rarity, RarityAttributes, RarityAttributes__factory, RarityCrafting, RarityCraftingMaterials, RarityCraftingMaterials__factory, RarityCrafting__factory, RarityGold, RarityGold__factory, RarityMasterworkItem, RarityMasterworkItem__factory, RarityMasterworkProject, RarityMasterworkProject__factory, RaritySkills, RaritySkills__factory, Rarity__factory } from '../../typechain'
import { skills as skillsenum, skillsArray } from './skills'

export interface IMockRarityContracts {
  core: MockContract<Rarity>,
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
  items: MockContract<RarityMasterworkItem>
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
  const items = await (await smock.mock<RarityMasterworkItem__factory>('RarityMasterworkItem')).deploy()
  await items.setVariable('rarity', rarity.core.address)
  await items.setVariable('projects', projects.address)
  return { codex: { weapons }, projects, items }
}

export async function mockRarity() : Promise<IMockRarityContracts> {
  const core = await (await smock.mock<Rarity__factory>('rarity')).deploy()
  await core.setVariable('next_summoner', 1)
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
  return { core, attributes, gold, skills, mats, crafting }
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