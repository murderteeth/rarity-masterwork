import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'

describe('Attributes', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()
  })

  it('abilityScores', async function () {
    this.library.rarityFakeAttributes.ability_scores
      .whenCalledWith(1)
      .returns([8, 2, 3, 4, 5, 6])
    const result = await this.library.attributes.abilityScores(1)
    expect(result.strength).to.equal(8)
    expect(result.dexterity).to.equal(2)
    expect(result.constitution).to.equal(3)
    expect(result.intelligence).to.equal(4)
    expect(result.wisdom).to.equal(5)
    expect(result.charisma).to.equal(6)
  })

  it('computeModifier', async function () {
    expect(await this.library.attributes.computeModifier(8)).to.equal(-1)
    expect(await this.library.attributes.computeModifier(10)).to.equal(0)
    expect(await this.library.attributes.computeModifier(11)).to.equal(0)
    expect(await this.library.attributes.computeModifier(12)).to.equal(1)
    expect(await this.library.attributes.computeModifier(14)).to.equal(2)
  })
})
