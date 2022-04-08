import chai, { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { ethers } from 'hardhat'
import { RarityCraftingMaterials2__factory } from '../../typechain/core/factories/RarityCraftingMaterials2__factory'
import { RarityAdventure2 } from '../../typechain/core'
import { randomId } from '../util'

chai.use(smock.matchers)

describe('Core: Crafting Materials II', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.adventure = await smock.fake<RarityAdventure2>('contracts/core/rarity_adventure-2.sol:rarity_adventure_2')
    this.mats = await(await smock.mock<RarityCraftingMaterials2__factory>('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')).deploy()
    await this.mats.setVariable('ADVENTURE_2', this.adventure.address)
  })

  beforeEach(async function() {
    this.adventure_token = randomId()
    this.adventure.isApprovedOrOwnerOfAdventure
    .whenCalledWith(this.adventure_token)
    .returns(true)
  })

  it('claims mats for slain monsters', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 1, 2, 2, 0, false, false, false, false, false])

    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 0)
    .returns([true, 0, 0, 0, 0, 0])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 1)
    .returns([false, 0, 0, 0, 0, 1])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 2)
    .returns([false, 0, 0, 0, 0, 2])

    this.adventure.monster_spawn
    .whenCalledWith(1)
    .returns(13)
    this.adventure.monster_spawn
    .whenCalledWith(2)
    .returns(1)

    await expect(this.mats.claim(this.adventure_token))
    .to.emit(this.mats, 'Transfer')
    .withArgs(
      ethers.constants.AddressZero, 
      this.signer.address, 
      ethers.utils.parseEther((800 + 25).toString())
    )
  })

  it('claims extra mats for a succesful search check', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 1, 2, 2, 0, false, false, true, true, false])

    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 0)
    .returns([true, 0, 0, 0, 0, 0])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 1)
    .returns([false, 0, 0, 0, 0, 1])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 2)
    .returns([false, 0, 0, 0, 0, 2])

    this.adventure.monster_spawn
    .whenCalledWith(1)
    .returns(13)
    this.adventure.monster_spawn
    .whenCalledWith(2)
    .returns(1)

    await expect(this.mats.claim(this.adventure_token))
    .to.emit(this.mats, 'Transfer')
    .withArgs(
      ethers.constants.AddressZero, 
      this.signer.address, 
      ethers.utils.parseEther((Math.floor(1.15 * (800 + 25))).toString())
    )
  })

  it('claims even more mats for a critical search check', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 1, 2, 2, 0, false, false, true, true, true])

    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 0)
    .returns([true, 0, 0, 0, 0, 0])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 1)
    .returns([false, 0, 0, 0, 0, 1])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 2)
    .returns([false, 0, 0, 0, 0, 2])

    this.adventure.monster_spawn
    .whenCalledWith(1)
    .returns(13)
    this.adventure.monster_spawn
    .whenCalledWith(2)
    .returns(1)

    await expect(this.mats.claim(this.adventure_token))
    .to.emit(this.mats, 'Transfer')
    .withArgs(
      ethers.constants.AddressZero, 
      this.signer.address, 
      ethers.utils.parseEther((Math.floor(1.20 * (800 + 25))).toString())
    )
  })

  it('rejects claimed adventures', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 1, 2, 2, 0, false, false, false, false, false])

    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 0)
    .returns([true, 0, 0, 0, 0, 0])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 1)
    .returns([false, 0, 0, 0, 0, 1])
    this.adventure.turn_orders
    .whenCalledWith(this.adventure_token, 2)
    .returns([false, 0, 0, 0, 0, 2])

    this.adventure.monster_spawn
    .whenCalledWith(1)
    .returns(13)
    this.adventure.monster_spawn
    .whenCalledWith(2)
    .returns(1)

    await this.mats.claim(this.adventure_token)

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('claimed')
  })

  it('rejects adventures that haven\'t ended', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 0, 2, 0, 0, false, false, false, false, false])

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('!ended')
  })

  it('rejects adventures that weren\'t won', async function() {
    this.adventure.adventures
    .whenCalledWith(this.adventure_token)
    .returns([0, 0, 1, 2, 1, 0, false, false, false, false, false])

    await expect(this.mats.claim(this.adventure_token))
    .revertedWith('!victory')
  })
})