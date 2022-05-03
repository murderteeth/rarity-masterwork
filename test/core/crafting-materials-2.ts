import chai, { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { ethers } from 'hardhat'
import { RarityCraftingMaterials2__factory } from '../../typechain/core/factories/RarityCraftingMaterials2__factory'
import { RarityAdventure2 } from '../../typechain/core'
import { randomId } from '../util'
import { fakeRarity } from '../util/fakes'

chai.use(smock.matchers)

describe('Core: Crafting Materials II', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.rarity = await fakeRarity()
    this.adventure = await smock.fake<RarityAdventure2>('contracts/core/rarity_adventure-2.sol:rarity_adventure_2')
    this.mats = await(await smock.mock<RarityCraftingMaterials2__factory>('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')).deploy()
    await this.mats.setVariable('ADVENTURE_2', this.adventure.address)
  })

  beforeEach(async function() {
    this.adventure_token = randomId()
    this.adventure.getApproved
    .whenCalledWith(this.adventure_token)
    .returns(this.signer.address)
  })

  it('claims mats for slain monsters', async function() {
    this.adventure.is_ended
    .whenCalledWith(this.adventure_token)
    .returns(true)

    this.adventure.is_victory
    .whenCalledWith(this.adventure_token)
    .returns(true)

    this.adventure['count_loot(uint256)']
    .whenCalledWith(this.adventure_token)
    .returns(100)

    await expect(this.mats.claim(this.adventure_token))
    .to.emit(this.mats, 'Transfer')
    .withArgs(
      ethers.constants.AddressZero, 
      this.signer.address, 
      100
    )
  })

  it('rejects claimed adventures', async function() {
    this.adventure.is_ended
    .whenCalledWith(this.adventure_token)
    .returns(true)

    this.adventure.is_victory
    .whenCalledWith(this.adventure_token)
    .returns(true)

    this.adventure['count_loot(uint256)']
    .whenCalledWith(this.adventure_token)
    .returns(100)

    await this.mats.claim(this.adventure_token)

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('claimed')
  })

  it('rejects adventures that haven\'t ended', async function() {
    this.adventure.is_ended
    .whenCalledWith(this.adventure_token)
    .returns(false)

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('!ended')
  })

  it('rejects adventures that weren\'t won', async function() {
    this.adventure.is_ended
    .whenCalledWith(this.adventure_token)
    .returns(true)

    this.adventure.is_victory
    .whenCalledWith(this.adventure_token)
    .returns(false)

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('!victory')
  })
})