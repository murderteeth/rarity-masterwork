const usedIds:number[] = [0]
export function randomId() {
  let result = Math.floor(Math.random() * 1_000_000)
  while(usedIds.includes(result)) {
    result = Math.floor(Math.random() * 1_000_000)
  }
  return result
}

export const equipmentType = {
  weapon: 0,
  armor: 1
}