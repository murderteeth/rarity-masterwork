import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { RarityAttributes, RarityFeats, RaritySkills } from '../../typechain/core'
import { Armor__factory } from '../../typechain/library/factories/Armor__factory'
import { Random__factory, SkillCheck__factory, Skills__factory } from '../../typechain/library'
import { Feats__factory } from '../../typechain/library/factories/Feats__factory'
import { IRarityCodexBaseRandom2 } from '../../typechain/interfaces/codex'
import { skills } from '../util/skills'
import { feats } from '../util/feats'

describe('Library: SkillCheck', function () {
  before(async function () {
    this.summoner = randomId()

    this.codex = {
      random: await smock.fake<IRarityCodexBaseRandom2>('contracts/codex/codex-base-random-2.sol:codex', { 
        address: '0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18'
      })
    }

    this.core = {
      attributes: await smock.fake<RarityAttributes>('contracts/core/attributes.sol:rarity_attributes', { 
        address: '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1'
      }),
      skills: await smock.fake<RaritySkills>('contracts/core/skills.sol:rarity_skills', {
        address: '0x51C0B29A1d84611373BA301706c6B4b72283C80F'
      }),
      feats: await smock.fake<RarityFeats>('contracts/core/feats.sol:rarity_feats', {
        address: '0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a'
      })
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

    this.core.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 0, 0, 0, 0, 0])

    this.core.skills.get_skills
    .whenCalledWith(this.summoner)
    .returns(Array(36).fill(0))

    this.core.feats.get_feats
    .whenCalledWith(this.summoner)
    .returns(Array(100).fill(false))
  })

  it('makes sense motive check', async function () {
    this.codex.random.dn.returns(17)
    expect(await this.library.skillcheck.senseMotive(this.summoner)).to.deep.eq([17, 16])

    this.core.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 0, 0, 0, 10, 0])
    expect(await this.library.skillcheck.senseMotive(this.summoner)).to.deep.eq([17, 17])

    const skillsRanks = Array(36).fill(0)
    skillsRanks[skills.sense_motive] = 1
    this.core.skills.get_skills
    .whenCalledWith(this.summoner)
    .returns(skillsRanks)
    expect(await this.library.skillcheck.senseMotive(this.summoner)).to.deep.eq([17, 18])

    const featFlags = Array(100).fill(false)
    featFlags[feats.negotiator] = true
    this.core.feats.get_feats
    .whenCalledWith(this.summoner)
    .returns(featFlags)
    expect(await this.library.skillcheck.senseMotive(this.summoner)).to.deep.eq([17, 20])
  })

})