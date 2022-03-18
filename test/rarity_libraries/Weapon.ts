import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'

describe('Weapon', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()
  })

  it('fromCodex', async function () {
    const result = await this.library.weapon.fromCodex(25) // battle axe
    expect(result.damage).to.equal(8)
    expect(result.critical).to.equal(3)
    expect(result.proficiency).to.equal(2)
  })
})
