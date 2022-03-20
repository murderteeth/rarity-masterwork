import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { Rarity__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { Rarity } from '../../typechain/core'

chai.use(smock.matchers)

describe('Core: Adventure (II)', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]

    this.rarity = await smock.fake<Rarity>('contracts/core/rarity.sol:rarity', { 
      address: '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb' 
    })

    this.adventure = await(await smock.mock<RarityAdventure2__factory>('contracts/core/rarity_adventure-2.sol:rarity_adventure_2', {
      libraries: {
        Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
      }
    })).deploy()

    this.summoner = () => {
      const summoner = randomId()
      this.rarity.ownerOf
      .whenCalledWith(summoner)
      .returns(this.signer.address)
      return summoner
    }
  })

  it('starts new adventures', async function () {
    const summoner = this.summoner()
    const adventure = await this.adventure.next_token()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    expect((await this.adventure.adventures(adventure))['startedOn']).to.be.gt(0)
    expect(await this.adventure.activeAdventures(summoner)).to.eq(adventure)
  })

  it('prevents summoners from starting simultaneous adventures', async function () {
    const summoner = this.summoner()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    await expect(this.adventure.start(summoner)).to.be.revertedWith('activeAdventures[summoner] != 0')
  })

  it('authorizes the owner of an adventure', async function () {
    const summoner = this.summoner()
    const adventure = await this.adventure.next_token()
    await this.adventure.start(summoner)
    expect(await this.adventure.isApprovedOrOwnerOfAdventure(adventure)).to.be.true
  })

  it('authorizes address approved for an adventure', async function () {
    const summoner = this.summoner()
    const adventure = await this.adventure.next_token()
    await this.adventure.start(summoner)

    const approvedSigner = this.signers[1]
    const signersConnection = await this.adventure.connect(approvedSigner)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(adventure)).to.be.false
    await this.adventure.approve(approvedSigner.address, adventure)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(adventure)).to.be.true
  })

  it('authorizes address approved for all of the owner\'s adventures', async function () {
    const summoner = this.summoner()
    const adventure = await this.adventure.next_token()
    await this.adventure.start(summoner)

    const approvedSigner = this.signers[1]
    const signersConnection = await this.adventure.connect(approvedSigner)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(adventure)).to.be.false
    await this.adventure.setApprovalForAll(approvedSigner.address, true)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(adventure)).to.be.true
  })

  it('discovers the farmer\'s secret', async function () {
    const summoner = this.summoner()
    const adventure = await this.adventure.next_token()
    await this.adventure.start(summoner)

  })

  it('prevents sensing the farmer\'s motives more than once', async function () {

  })

  it('prevents sense motive if the adventure hasn\'t begun', async function () {

  })

  it('equips weapons and armor', async function () {

  })

  it('prevents equipping if the adventure hasn\'t begun', async function () {

  })

  it('prevents equipping if combat has begun', async function () {

  })

  it('enters the barn', async function () {

  })

  it('ends the adventure', async function () {

  })

})