export const monsters = {
  kobld: 1,
  dire_rat: 2,
  goblin: 3,
  gnoll: 4,
  grimlock: 5,
  black_bear: 6,
  ogre: 7,
  dire_boar: 8,
  dire_wolverine: 9,
  troll: 10,
  ettin: 11,
  hill_giant: 12,
  stone_giant: 13
}

export function getMonsterName(id: number) {
  return Object.keys(monsters)[id - 1]
}