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

export const equipmentType = {
  weapon: 0,
  armor: 1,
  shield: 2
}

export const enumberance = {
  unarmed: 1,
  lightMelee: 2,
  oneHanded: 3,
  twoHanded: 4,
  ranged: 5
}