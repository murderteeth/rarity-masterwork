export const skills = {
  appraise: 0,
  balance: 1,
  bluff: 2,
  climb: 3,
  concentration: 4,
  craft: 5,
  decipher_script: 6,
  diplomacy: 7,
  disable_device: 8,
  disguise: 9,
  escape_artist: 10,
  forgery: 11,
  gather_information: 12,
  handle_animal: 13,
  heal: 14,
  hide: 15,
  intimidate: 16,
  jump: 17,
  knowledge: 18,
  listen: 19,
  move_silently: 20,
  open_lock: 21,
  perform: 22,
  profession: 23,
  ride: 24,
  search: 25,
  sense_motive: 26,
  sleight_of_hand: 27,
  speak_language: 28,
  spellcraft: 29,
  spot: 30,
  survival: 31,
  swim: 32,
  tumble: 33,
  use_magic_device: 34,
  use_rope: 35
}

export function getSkill(id: number) {
  return Object.keys(skills)[id - 1]
}

export function skillsArray(...points: { index: number, points: number }[]) {
  const result = Array(36).fill(0)
  points.forEach(p => result[p.index] = p.points)
  return result.reverse()
}