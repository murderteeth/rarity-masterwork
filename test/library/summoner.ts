import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Rarity } from '../../typechain/core'
import { Summoner__factory } from '../../typechain/library'

describe('Library: Summoner', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.approved = this.signers[1]
    this.approvedForAll = this.signers[2]
    this.rando = this.signers[3]
    this.summoner = randomId()

    this.rarity = await smock.fake<Rarity>('contracts/core/rarity.sol:rarity', { 
      address: '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb' 
    })

    this.library = {
      summoner: await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner')).deploy()
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
    const contract = await this.library.summoner.connect(this.rando.address)
    expect(await contract.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.false
  })

  it('authorizes the owner of a summoner', async function () {
    expect(await this.library.summoner.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

  it('authorizes address approved for a summoner', async function () {
    const contract = await this.library.summoner.connect(this.approved.address)
    expect(await this.library.summoner.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

  it('authorizes address approved for all of the owner\'s summoners', async function () {
    const contract = await this.library.summoner.connect(this.approvedForAll.address)
    expect(await this.library.summoner.isApprovedOrOwnerOfSummoner(this.summoner)).to.be.true
  })

})