import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { armorType, baseType } from '../util/crafting'
import { Armor__factory } from '../../typechain/library/factories/Armor__factory'
import { fakeAttributes, fakeCommonCrafting } from '../util/fakes'

describe('Library: Armor', function () {
  before(async function () {
    this.summoner = randomId()
    this.leatherArmor = randomId()

    this.attributes = await fakeAttributes()
    this.commonCrafting = await fakeCommonCrafting()

    this.library = {
      armor: await(await smock.mock<Armor__factory>('contracts/library/Armor.sol:Armor', {
        libraries: {
          Attributes: (await (await smock.mock<Armor__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address
        }
      })).deploy()
    }
  })

  it('computes armor class', async function () {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    this.commonCrafting.items
    .whenCalledWith(this.leatherArmor)
    .returns([baseType.armor, armorType.leather, 0, 0])

    const ac = await this.library.armor.class(this.summoner, this.leatherArmor, this.commonCrafting.address)
    expect(ac).to.equal(13)
  })

})