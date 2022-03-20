import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { armorType, baseType } from '../util/crafting'
import { RarityAttributes, RarityCrafting } from '../../typechain/core'
import { Armor__factory } from '../../typechain/library/factories/Armor__factory'

describe('Library: Armor', function () {
  before(async function () {
    this.summoner = randomId()
    this.leatherArmor = randomId()

    this.attributes = await smock.fake<RarityAttributes>('contracts/core/attributes.sol:rarity_attributes', { 
      address: '0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1'
    })

    this.commonCrafting = await smock.fake<RarityCrafting>('contracts/core/rarity_crafting_common.sol:rarity_crafting', { 
      address: '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC'
    })

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