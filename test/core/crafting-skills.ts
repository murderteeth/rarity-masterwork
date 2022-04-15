import chai, { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { fakeRarity, fakeSkills, fakeSummoner } from '../util/fakes'
import { RarityCraftingSkills__factory } from '../../typechain/core'
import { Rarity__factory, Skills__factory } from '../../typechain/library'
import { skills } from '../util/skills'
import { craftingSkills } from '../util/crafting'
import { ethers } from 'hardhat'
import { classes } from '../util/classes'

chai.use(smock.matchers)

describe('Core: Crafting Skills', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]

    this.core = {
      rarity: await fakeRarity(),
      skills: await fakeSkills()
    }
    this.craftingSkills = await(await smock.mock<RarityCraftingSkills__factory>('contracts/core/rarity_crafting_skills.sol:rarity_crafting_skills', {
      libraries: {
        Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
        Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address
      }
    })).deploy()
  })

  it('redeems specialist ranks for craft ranks', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer);
    const baseSkillRanks = Array(36).fill(0)
    baseSkillRanks[skills.craft] = 10
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(baseSkillRanks)

    const craftSkillsRanks = Array(5).fill(0)
    craftSkillsRanks[craftingSkills.weaponsmithing - 1] = 10
    await this.craftingSkills.set_skills(summoner, craftSkillsRanks)
    expect(await this.craftingSkills.get_skills(summoner))
    .to.deep.eq([0, 0, 0, 0, 10])
  })

  it('can\'t overspend craft ranks', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer);
    const baseSkillRanks = Array(36).fill(0)
    baseSkillRanks[skills.craft] = 0
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(baseSkillRanks)

    const craftSkillsRanks = Array(5).fill(0)
    craftSkillsRanks[craftingSkills.weaponsmithing - 1] = 1
    await expect(this.craftingSkills.set_skills(summoner, craftSkillsRanks))
    .to.be.revertedWith('redeem_craft_ranks > base_craft_ranks')
  })

  it('can\'t lower specialist ranks', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer);
    const baseSkillRanks = Array(36).fill(0)
    baseSkillRanks[skills.craft] = 10
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(baseSkillRanks)

    const craftSkillsRanks = Array(5).fill(0)
    craftSkillsRanks[craftingSkills.weaponsmithing - 1] = 10
    await this.craftingSkills.set_skills(summoner, craftSkillsRanks)

    craftSkillsRanks[craftingSkills.weaponsmithing - 1] = 9
    await expect(this.craftingSkills.set_skills(summoner, craftSkillsRanks))
    .to.be.revertedWith('skills[i] < current_skills[i]')
  })

  it('redeems alchemy ranks for spellcasters', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer);
    this.core.rarity.class
    .whenCalledWith(summoner)
    .returns(classes.wizard)

    const baseSkillRanks = Array(36).fill(0)
    baseSkillRanks[skills.craft] = 10
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(baseSkillRanks)

    const craftSkillsRanks = Array(5).fill(0)
    craftSkillsRanks[craftingSkills.alchemy - 1] = 10
    await this.craftingSkills.set_skills(summoner, craftSkillsRanks)
    expect(await this.craftingSkills.get_skills(summoner))
    .to.deep.eq([10, 0, 0, 0, 0])
  })

  it('can\'t redeem alchemy ranks for non-spellcasters', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer);
    this.core.rarity.class
    .whenCalledWith(summoner)
    .returns(classes.barbarian)

    const baseSkillRanks = Array(36).fill(0)
    baseSkillRanks[skills.craft] = 10
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(baseSkillRanks)

    const craftSkillsRanks = Array(5).fill(0)
    craftSkillsRanks[craftingSkills.alchemy - 1] = 10
    await expect(this.craftingSkills.set_skills(summoner, craftSkillsRanks))
    .to.be.revertedWith('!is_spell_caster(summoner)')
  })
})