import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'
import { smock } from '@defi-wonderland/smock'
import { RarityCrafting } from '../../typechain'

describe('Armor', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()

    this.mockArmorContract = await smock.fake<RarityCrafting>(
      'rarity_crafting',
      {
        address: '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC'
      }
    )
  })

  it.only('class', async function () {
    // 10 dex
    this.library.rarityFakeAttributes.ability_scores
      .whenCalledWith(1)
      .returns([0, 10, 0, 0, 0, 0])

    // Item type: leather armor (2)
    this.mockArmorContract.items.whenCalledWith(1).returns([0, 2, 0, 0])

    const res = await this.library.armor.class(
      1,
      1,
      this.mockArmorContract.address
    )
    // 2 armor bonus using leather armor, 0 dex bonus for 10 dex
    // even if not proficient, leather does not have a penalty
    expect(res).to.equal(12)
  })

  it('proficiencyBonus', async function () {})
})
