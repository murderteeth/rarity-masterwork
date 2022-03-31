import { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Rarity__factory } from '../../typechain/library'
import { fakeCommonCrafting, fakeLongsword, fakeRarity } from '../util/fakes'

describe('Library: Crafting', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.approved = this.signers[1]
    this.approvedForAll = this.signers[2]
    this.rando = this.signers[3]

    this.crafting = {
      common: await fakeCommonCrafting()
    }

    this.library = {
      crafting: await(await smock.mock<Rarity__factory>('contracts/library/Crafting.sol:Crafting')).deploy()
    }

    this.craft = fakeLongsword(this.crafting.common, randomId(), this.signer)

    this.crafting.common.getApproved
    .whenCalledWith(this.craft)
    .returns(this.approved.address)

    this.crafting.common.isApprovedForAll
    .whenCalledWith(this.signer.address, this.approvedForAll.address)
    .returns(true)
  })

  it('rejects randos', async function () {
    const library = await this.library.crafting.connect(this.rando.address)
    expect(await library.isApprovedOrOwnerOfItem(this.craft, this.crafting.common.address)).to.be.false
  })

  it('authorizes the owner of an item', async function () {
    expect(await this.library.crafting.isApprovedOrOwnerOfItem(this.craft, this.crafting.common.address)).to.be.true
  })

  it('authorizes address approved for an item', async function () {
    const library = await this.library.crafting.connect(this.approved.address)
    expect(await library.isApprovedOrOwnerOfItem(this.craft, this.crafting.common.address)).to.be.true
  })

  it('authorizes address approved for all of the owner\'s items', async function () {
    const library = await this.library.crafting.connect(this.approvedForAll.address)
    expect(await library.isApprovedOrOwnerOfItem(this.craft, this.crafting.common.address)).to.be.true
  })

})