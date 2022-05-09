import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

const usedIds:number[] = [0]
export function randomId() {
  let result = Math.floor(Math.random() * 1_000_000)
  while(usedIds.includes(result)) {
    result = Math.floor(Math.random() * 1_000_000)
  }
  return result
}

export function humanEther(wei: BigNumber) {
  return parseFloat(ethers.utils.formatEther(wei))
}

export function clean(object: any) {
  Object.keys(object).forEach(key => {
    if (isNumber(key)) delete object[key]
  })
  return object
}

export function isNumber(value: string | number): boolean
{
  return ((value != null)
    && (value !== '') 
    && !isNaN(Number(value.toString())))
}

export const equipmentSlot = {
  weapon1: 1,
  armor: 2,
  shield: 3,
  weapon2: 4,
  hands: 5,
  ring1: 6,
  ring2: 7,
  head: 8,
  headband: 9,
  eyes: 10,
  neck: 11,
  shoulders: 12,
  chest: 13,
  belt: 14,
  body: 15,
  arms: 16,
  feet: 17
}

export const enumberance = {
  unarmed: 1,
  lightMelee: 2,
  oneHanded: 3,
  twoHanded: 4,
  ranged: 5
}

export const damageType = {
  bludgeoning: 1,
  piercing: 2,
  slashing: 3
}

export function getDamageType(id: number) {
  return Object.keys(damageType)[id - 1]
}

export function unpackAttacks(attacksPack: number[]) {
  const result = []
  for(let i = 0; i < 4; i ++) {
    if(attacksPack[7 * (i + 1) - 1] > 0) {
      result.push({
        attack_bonus: attacksPack[7 * i + 0],
        critical_modifier: attacksPack[7 * i + 1],
        critical_multiplier: attacksPack[7 * i + 2],
        damage_dice_count: attacksPack[7 * i + 3],
        damage_dice_sides: attacksPack[7 * i + 4],
        damage_modifier: attacksPack[7 * i + 5],
        damage_type: attacksPack[7 * i + 6]
      })
    }
  }
  return result
} 