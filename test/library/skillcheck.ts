import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Armor__factory } from '../../typechain/library/factories/Armor__factory'
import { Random__factory, SkillCheck__factory, Skills__factory } from '../../typechain/library'
import { Feats__factory } from '../../typechain/library/factories/Feats__factory'
import { skills } from '../util/skills'
import { feats } from '../util/feats'
import { fakeAttributes, fakeFeats, fakeRandom, fakeSkills } from '../util/fakes'

describe('Library: SkillCheck', function () {
  before(async function () {
    this.summoner = randomId()

    this.codex = {
      random: await fakeRandom()
    }

    this.core = {
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      feats: await fakeFeats()
    }

    this.library = {
      skillcheck: await(await smock.mock<SkillCheck__factory>('contracts/library/SkillCheck.sol:SkillCheck', {
        libraries: {
          Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
          Attributes: (await (await smock.mock<Armor__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
          Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address
        }
      })).deploy()
    }
  })

  it('makes sense motive check', async function () {
    this.codex.random.dn.returns(17)
    expect(await this.library.skillcheck.senseMotive(this.summoner))
    .to.deep.eq([17, 16])

    this.core.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 0, 0, 0, 10, 0])
    expect(await this.library.skillcheck.senseMotive(this.summoner))
    .to.deep.eq([17, 17])

    const skillsRanks = Array(36).fill(0)
    skillsRanks[skills.sense_motive] = 1
    this.core.skills.get_skills
    .whenCalledWith(this.summoner)
    .returns(skillsRanks)
    expect(await this.library.skillcheck.senseMotive(this.summoner))
    .to.deep.eq([17, 18])

    const featFlags = Array(100).fill(false)
    featFlags[feats.negotiator] = true
    this.core.feats.get_feats
    .whenCalledWith(this.summoner)
    .returns(featFlags)
    expect(await this.library.skillcheck.senseMotive(this.summoner))
    .to.deep.eq([17, 20])
  })

})