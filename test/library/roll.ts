import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Attributes__factory, Random__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { Feats__factory } from '../../typechain/library/factories/Feats__factory'
import { fakeAttributes, fakeCraftingSkills, fakeFeats, fakeRandom, fakeSkills } from '../util/fakes'
import { feats } from '../util/feats'
import { skills } from '../util/skills'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { craftingSkills } from '../util/crafting'

describe('Library: Roll', function () {
  before(async function () {
    this.codex = {
      random: await fakeRandom()
    }

    this.core = {
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      craftingSkills: await fakeCraftingSkills(),
      feats: await fakeFeats()
    }

    this.library = {
      roll: await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
        libraries: {
          Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
          Skills: (await(await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
          CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
        }
      })).deploy()
    }
  })

  beforeEach(async function() {
    this.summoner = randomId()
  })

  describe('Craft', async function() {
    it('rolls low for dumb dumbs', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 9, 0, 0])
      expect(await this.library.roll.craft(this.summoner, craftingSkills.unspecialized))
      .to.deep.eq([1, 0])
    })

    it('rolls higher for smart summoners', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 18, 0, 0])
      expect(await this.library.roll.craft(this.summoner, craftingSkills.unspecialized))
      .to.deep.eq([1, 5])
    })

    it('rolls higher for skilled summoners', async function() {
      this.codex.random.dn.returns(1)
      const skillsRanks = Array(36).fill(0)
      skillsRanks[skills.craft] = 4
      this.core.skills.get_skills
      .whenCalledWith(this.summoner)
      .returns(skillsRanks)
      expect(await this.library.roll.craft(this.summoner, craftingSkills.unspecialized))
      .to.deep.eq([1, 4])
    })

    it('rolls for specialized skills', async function() {
      this.codex.random.dn.returns(1)

      const craftSkillsRanks = Array(5).fill(0)
      craftSkillsRanks[craftingSkills.weaponsmithing - 1] = 10
      this.core.craftingSkills.get_skills
      .whenCalledWith(this.summoner)
      .returns(craftSkillsRanks)

      expect(await this.library.roll.craft(this.summoner, craftingSkills.weaponsmithing))
      .to.deep.eq([1, 10])
    })
  })

  describe('Initiative', async function() {
    it('rolls low for clumsy summoners', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 9, 0, 0, 0, 0])
      expect(await this.library.roll['initiative(uint256)'](this.summoner)).to.deep.eq([1, 0])
    })

    it('rolls higher for dexterous summoners', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 18, 0, 0, 0, 0])
      expect(await this.library.roll['initiative(uint256)'](this.summoner)).to.deep.eq([1, 5])
    })

    it('rolls higher with the improved initiative feat', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 12, 0, 0, 0, 0])

      const featFlags = Array(100).fill(false)
      featFlags[feats.improved_initiative] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)

      expect(await this.library.roll['initiative(uint256)'](this.summoner)).to.deep.eq([1, 6])
    })
  })

  describe('Search', async function() {
    it('rolls low for dumb dumbs', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 9, 0, 0])
      expect(await this.library.roll.search(this.summoner))
      .to.deep.eq([1, 0])
    })

    it('rolls higher for smart summoners', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 18, 0, 0])
      expect(await this.library.roll.search(this.summoner))
      .to.deep.eq([1, 5])
    })

    it('rolls higher for skilled summoners', async function() {
      this.codex.random.dn.returns(1)
      const skillsRanks = Array(36).fill(0)
      skillsRanks[skills.search] = 4
      this.core.skills.get_skills
      .whenCalledWith(this.summoner)
      .returns(skillsRanks)
      expect(await this.library.roll.search(this.summoner))
      .to.deep.eq([1, 4])
    })

    it('rolls higher with the investigator feat', async function() {
      this.codex.random.dn.returns(1)
      const featFlags = Array(100).fill(false)
      featFlags[feats.investigator] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)
      expect(await this.library.roll.search(this.summoner))
      .to.deep.eq([1, 2])
    })
  })

  describe('Sense Motive', async function() {
    it('rolls low for foolish summoners', async function() {
      this.codex.random.dn.returns(1)
      expect(await this.library.roll.sense_motive(this.summoner))
      .to.deep.eq([1, 0])
    })

    it('rolls higher for wise summoners', async function() {
      this.codex.random.dn.returns(1)
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 0, 18, 0])
      expect(await this.library.roll.sense_motive(this.summoner))
      .to.deep.eq([1, 5])
    })

    it('rolls higher for skilled summoners', async function() {
      this.codex.random.dn.returns(1)
      const skillsRanks = Array(36).fill(0)
      skillsRanks[skills.sense_motive] = 4
      this.core.skills.get_skills
      .whenCalledWith(this.summoner)
      .returns(skillsRanks)
      expect(await this.library.roll.sense_motive(this.summoner))
      .to.deep.eq([1, 4])
    })

    it('rolls higher with the negotiator feat', async function() {
      this.codex.random.dn.returns(1)
      const featFlags = Array(100).fill(false)
      featFlags[feats.negotiator] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)
      expect(await this.library.roll.sense_motive(this.summoner))
      .to.deep.eq([1, 2])
    })
  })

  describe('Attack', async function() {
    it('rolls a critical miss', async function () {
      this.codex.random.dn.returns(1)
      const result = await this.library.roll.attack(this.summoner, 1, -1, 2, 15)
      expect(result.roll).to.eq(1)
      expect(result.score).to.eq(0)
      expect(result.critical_roll).to.eq(0)
      expect(result.critical_confirmation).to.eq(0)
      expect(result.damage_multiplier).to.eq(0)
    })

    it('rolls a miss', async function () {
      this.codex.random.dn.returns(10)
      const result = await this.library.roll.attack(this.summoner, 1, -1, 2, 15)
      expect(result.roll).to.eq(10)
      expect(result.score).to.eq(11)
      expect(result.critical_roll).to.eq(0)
      expect(result.critical_confirmation).to.eq(0)
      expect(result.damage_multiplier).to.eq(0)
    })

    it('rolls a hit', async function () {
      this.codex.random.dn.returns(14)
      const result = await this.library.roll.attack(this.summoner, 1, -1, 2, 15)
      expect(result.roll).to.eq(14)
      expect(result.score).to.eq(15)
      expect(result.critical_roll).to.eq(0)
      expect(result.critical_confirmation).to.eq(0)
      expect(result.damage_multiplier).to.eq(1)
    })

    it('rolls a critical hit', async function () {
      this.codex.random.dn.returns(19)
      const result = await this.library.roll.attack(this.summoner, 1, -1, 2, 15)
      expect(result.roll).to.eq(19)
      expect(result.score).to.eq(20)
      expect(result.critical_roll).to.eq(19)
      expect(result.critical_confirmation).to.eq(20)
      expect(result.damage_multiplier).to.eq(3)
    })
  })

  describe('Damage', async function() {
    it('rolls 1d8+1 x1 max', async function() {
      this.codex.random.dn.returns(8)
      expect(await this.library.roll.damage(this.summoner, 1, 8, 1, 1)).to.eq(9)
    })

    it('rolls 1d8+1 x1 min', async function() {
      this.codex.random.dn.returns(1)
      expect(await this.library.roll.damage(this.summoner, 1, 8, 1, 1)).to.eq(2)
    })

    it('rolls 2d6-1 x2 max', async function() {
      this.codex.random.dn.returns(6)
      expect(await this.library.roll.damage(this.summoner, 2, 6, -1, 2)).to.eq(22)
    })

    it('rolls 2d6-1 x2 min', async function() {
      this.codex.random.dn.returns(1)
      expect(await this.library.roll.damage(this.summoner, 2, 6, -1, 2)).to.eq(2)
    })

    it('rolls at least 1', async function() {
      this.codex.random.dn.returns(1)
      expect(await this.library.roll.damage(this.summoner, 1, 12, -100, 1)).to.eq(1)
    })
  })

})