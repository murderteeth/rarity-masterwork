import { ethers } from 'hardhat'
import codex from '../../contracts/codex/json/equipment.json'

export const officialWeapons = codex.equipments.equipment.filter(e => e.family === 'Weapons')
export const officialArmor = codex.equipments.equipment.filter(e => e.family === 'Armor and Shields')

function weaponCategoryToProficiency(category: string) {
  if(category.startsWith('Simple')) return 1
  if(category.startsWith('Martial')) return 2
  if(category.startsWith('Exotic')) return 3
}

function weaponSubCategoryToEncumbrance(subcategory?: string) {
  if(subcategory?.startsWith('Unarmed')) return 1
  if(subcategory?.startsWith('Light Melee')) return 2
  if(subcategory?.startsWith('One-Handed')) return 3
  if(subcategory?.startsWith('Two-Handed')) return 4
  if(subcategory?.startsWith('Ranged')) return 5
}

function weaponTypeToDamageType(type?: string) {
  if(type?.startsWith('Bludgeoning')) return 1
  if(type?.startsWith('Piercing')) return 2
  if(type?.startsWith('Slashing')) return 3
}

function weaponDamageToDamage(damage?: string) {
  const re = /^(\d)d(\d)$/
  const match = damage?.match(re)
  if(!match) return 0
  return parseInt(match[1]) * parseInt(match[2])
}

function weaponCriticalToParts(critical?: string) {
  const re = /^(((\d{2})-(\d{2}))\/)?x(\d)$/
  const match = critical?.match(re)
  if(!match) return { range: 0, multiplier: 0 }
  return {
    modifier: match[3] ? parseInt(match[3]) - parseInt(match[4]) : 0,
    multiplier: parseInt(match[5])
  }
}

function weaponRangeToRange(range?: string) {
  if(!range || range === "-") return 0
  return parseInt(range.replace(' ft.', ''))
}

function costToGp(cost: string) {
  return ethers.utils.parseEther(cost.replace(',', '').replace(' gp', ''))
}

export function weapons(name: string, masterwork?: boolean) {
  const index = officialWeapons.findIndex(w => w.name.toLowerCase() === name.toLowerCase())
  const official = officialWeapons[index]
  return {
    id: 0,
    name: official.name,
    cost: costToGp(official.cost).add(masterwork ? ethers.utils.parseEther('300') : 0),
    proficiency: weaponCategoryToProficiency(official.category),
    encumbrance: weaponSubCategoryToEncumbrance(official.subcategory),
    damage_type: weaponTypeToDamageType(official.type),
    weight: parseInt(official.weight?.replace(' lb.', '') || '0'),
    damage: weaponDamageToDamage(official.dmg_m),
    critical: weaponCriticalToParts(official.critical).multiplier,
    critical_modifier: weaponCriticalToParts(official.critical).modifier,
    range_increment: weaponRangeToRange(official.range_increment),
    description: official.full_text
  }
}

function armorSubCategoryToProficiency(subcategory?: string) {
  if(!subcategory) return 0
  if(subcategory.startsWith('Light armor')) return 1
  if(subcategory.startsWith('Medium armor')) return 2
  if(subcategory.startsWith('Heavy armor')) return 3
  if(subcategory.startsWith('Shields')) return 4
}

export function armors(name: string, masterwork?: boolean) {
  const index = officialArmor.findIndex(a => a.name.toLowerCase() === name.toLowerCase())
  const official = officialArmor[index]
  return {
    id: 0,
    proficiency: armorSubCategoryToProficiency(official.subcategory),
    weight: parseInt(official.weight?.replace(' lb.', '') || '0'),
    armor_bonus: official.armor_shield_bonus,
    max_dex_bonus: official.armor_shield_bonus,
    penalty: official.armor_check_penalty,
    spell_failure: parseInt(official.arcane_spell_failure_chance?.replace('%', '') || '0'),
    cost: costToGp(official.cost).add(masterwork ? ethers.utils.parseEther('150') : 0),
    name: official.name,
    description: official.full_text
  }
}