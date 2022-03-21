import { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Rarity__factory } from '../../typechain/library'
import { fakeRarity } from '../util/fakes'

describe('Library: Rarity', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.approved = this.signers[1]
    this.approvedForAll = this.signers[2]
    this.rando = this.signers[3]
    this.summoner = randomId()

    this.rarity = await fakeRarity()

    this.library = {
      rarity: await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()
    }

    this.rarity.ownerOf
    .whenCalledWith(this.summoner)
    .returns(this.signer.address)

    this.rarity.getApproved
    .whenCalledWith(this.summoner)
    .returns(this.approved.address)

    this.rarity.isApprovedForAll
    .whenCalledWith(this.signer.address, this.approvedForAll.address)
    .returns(true)
  })

  it('rejects randos', async function () {
    const contract = await this.library.rarity.connect(this.rando.address)
    expect(await contract.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.false
  })

  it('authorizes the owner of a summoner', async function () {
    expect(await this.library.rarity.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

  it('authorizes address approved for a summoner', async function () {
    const contract = await this.library.rarity.connect(this.approved.address)
    expect(await contract.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

  it('authorizes address approved for all of the owner\'s summoners', async function () {
    const contract = await this.library.rarity.connect(this.approvedForAll.address)
    expect(await contract.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

})