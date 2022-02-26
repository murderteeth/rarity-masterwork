import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'
import { smock } from '@defi-wonderland/smock'
import { CodexRandom } from '../../typechain/CodexRandom'
import { RarityCrafting } from '../../typechain'

describe('Combat', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()

    this.mockRandom = await smock.fake<CodexRandom>('codex_random', {
      address: '0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18'
    })
    this.mockRandom.dn.returns(10)
    // 12 dex
    this.library.rarityFakeAttributes.ability_scores
      .whenCalledWith(1)
      .returns([10, 12, 0, 0, 0, 0])
  })

  it('initiative', async function () {
    const res = await this.library.combat.initiative(1, 5, -2)

    // Initiative is roll + modifier (12 dex = +1) + penalty/bonus passed in (-2) + bonus (5)
    expect(res).to.eq(10 + 1 - 2 + 5)
  })

  it('basicFullAttack', async function () {
    const weaponId = 25 // battle axe
    const targetAC = 15
    const contract = '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC'

    this.library.rarityFakeCore.level.whenCalledWith(1).returns(5)
    this.library.rarityFakeCore.class.whenCalledWith(1).returns(1)

    this.mockWeaponContract = await smock.fake<RarityCrafting>(
      'rarity_crafting',
      {
        address: contract
      }
    )

    this.mockWeaponContract.items.whenCalledWith(1).returns([0, weaponId, 0, 0])

    const res = await this.library.combat.basicFullAttack(
      1,
      true,
      1,
      contract,
      targetAC,
      0,
      0
    )

    expect(res.attackRoll).to.equal(10) // This is the random we set
    expect(res.attackScore).to.equal(15) // Basic attack is 5
    expect(res.damage).to.equal(10) // 10 damage + 0 str modifier

    // TODO: Test critical hit
    // TODO: Test high level with secondary/tertiary hits
  })

  it('baseAttackBonusByClassAndLevel', async function () {
    // Level 6 fighter has 6 on their primary and 1 on their secondary
    // +6/+1
    // This function tests the primary
    // Class 5 is fighter, the "6" here is the level
    expect(
      await this.library.combat.baseAttackBonusByClassAndLevel(5, 6)
    ).to.equal(6)
  })
})
