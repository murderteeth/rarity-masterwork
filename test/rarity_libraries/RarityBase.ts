import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'

describe('RarityBase', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()
  })

  it('isApprovedOrOwnerOfSummoner', async function () {
    expect(await this.library.rarity.isApprovedOrOwnerOfSummoner(1)).to.be.false
    this.library.rarityFakeCore.ownerOf
      .whenCalledWith(1)
      .returns(this.signer.address)
    expect(await this.library.rarity.isApprovedOrOwnerOfSummoner(1)).to.be.true
  })

  it('level', async function () {
    this.library.rarityFakeCore.level.whenCalledWith(1).returns(1)
    expect(await this.library.rarity.level(1)).to.equal(1)
  })
  it('class', async function () {
    this.library.rarityFakeCore.class.whenCalledWith(1).returns(1)
    expect(await this.library.rarity.class(1)).to.equal(1)
  })
})
