import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { Attributes__factory } from '../../typechain/library/factories/Attributes__factory'
import { randomId } from '../util'
import { fakeAttributes } from '../util/fakes'

describe('Library: Attributes', function () {
  before(async function () {
    this.summoner = randomId()

    this.attributes = await fakeAttributes()

    this.library = {
      attributes: await(await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()
    }
  })

  it('computes generic modifiers', async function () {
    expect(await this.library.attributes.computeModifier(8)).to.eq(-1)
    expect(await this.library.attributes.computeModifier(10)).to.eq(0)
    expect(await this.library.attributes.computeModifier(11)).to.eq(0)
    expect(await this.library.attributes.computeModifier(12)).to.eq(1)
    expect(await this.library.attributes.computeModifier(14)).to.eq(2)
  })

  it('computes strength modifier', async function () {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([8, 0, 0, 0, 0, 0])
    expect(await this.library.attributes.strengthModifier(this.summoner)).to.eq(-1)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])
    expect(await this.library.attributes.strengthModifier(this.summoner)).to.eq(0)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([11, 0, 0, 0, 0, 0])
    expect(await this.library.attributes.strengthModifier(this.summoner)).to.eq(0)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([12, 0, 0, 0, 0, 0])
    expect(await this.library.attributes.strengthModifier(this.summoner)).to.eq(1)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([14, 0, 0, 0, 0, 0])
    expect(await this.library.attributes.strengthModifier(this.summoner)).to.eq(2)
  })
})