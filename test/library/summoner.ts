import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { armorType, baseType } from '../util/crafting'
import { fakeAttributes, fakeCommonCrafting, fakeRarity } from '../util/fakes'
import { ethers } from 'hardhat'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { Attributes__factory, Feats__factory, Proficiency__factory, Rarity__factory } from '../../typechain/library'
import { classes } from '../util/classes'

describe('Library: Summoner', function () {
  before(async function () {
    this.summoner = randomId()
    this.fullPlate = randomId()

    this.rarity = await fakeRarity()
    this.attributes = await fakeAttributes()
    this.commonCrafting = await fakeCommonCrafting()

    this.library = {
      summoner: await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner', {
        libraries: {
          Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
          Proficiency: (await (await smock.mock<Proficiency__factory>('contracts/library/Proficiency.sol:Proficiency', {
            libraries: {
              Feats: (await (await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
              Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
            }
          })).deploy()).address,
          Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
        }
      })).deploy()
    }
  })

  it('computes hit points', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 0, 12, 0, 0, 0])

    const hp = await this.library.summoner.hit_points(this.summoner)
    expect(hp).to.eq(35)
  })

  it('computes minimum armor class', async function () {
    const ac = await this.library.summoner.armor_class(this.summoner, 0, ethers.constants.AddressZero)
    expect(ac).to.equal(9)
  })

  it('computes armor class without armor', async function () {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    const ac = await this.library.summoner.armor_class(this.summoner, 0, ethers.constants.AddressZero)
    expect(ac).to.equal(11)
  })

  it('computes armor class with non-proficient armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    this.commonCrafting.items
    .whenCalledWith(this.fullPlate)
    .returns([baseType.armor, armorType.fullPlate, 0, 0])

    const ac = await this.library.summoner.armor_class(this.summoner, this.fullPlate, this.commonCrafting.address)
    expect(ac).to.equal(13)
  })

  it('computes armor class with proficient armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    this.commonCrafting.items
    .whenCalledWith(this.fullPlate)
    .returns([baseType.armor, armorType.fullPlate, 0, 0])

    const ac = await this.library.summoner.armor_class(this.summoner, this.fullPlate, this.commonCrafting.address)
    expect(ac).to.equal(19)
  })
})