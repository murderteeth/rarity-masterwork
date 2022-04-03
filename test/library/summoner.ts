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

  it('computes basic attack bonus', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([5, 0, 0, 0])

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(6)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([6, 1, 0, 0])

    this.rarity.level // 11th level ~ October 2024
    .whenCalledWith(this.summoner)
    .returns(11)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([11, 6, 1, 0])

    this.rarity.level // 16th level ~ August 2030
    .whenCalledWith(this.summoner)
    .returns(16)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([16, 11, 6, 1])

    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([3, 0, 0, 0])

    this.rarity.level // 8th level ~ December 2022
    .whenCalledWith(this.summoner)
    .returns(8)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([6, 1, 0, 0])

    this.rarity.level // 15th level ~ February 2029
    .whenCalledWith(this.summoner)
    .returns(15)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([11, 6, 1, 0])

    this.rarity.level // 20th level ~ July 2038
    .whenCalledWith(this.summoner)
    .returns(20)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([15, 10, 5, 0])
  })
})