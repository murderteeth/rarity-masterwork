import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { mockLibrary } from './api/mocks'
import { smock } from '@defi-wonderland/smock'
import { CodexRandom } from '../../typechain/CodexRandom'

describe('Combat', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.library = await mockLibrary()

    this.mockRandom = await smock.fake<CodexRandom>('codex_random', {
      address: '0x1380be70F96D8Ce37f522bDd8214BFCc1FeC8E18'
    })
    this.mockRandom.dn.returns(10)
  })

  it('initiative', async function () {
    // 12 dex
    this.library.rarityFakeAttributes.ability_scores
      .whenCalledWith(1)
      .returns([0, 12, 0, 0, 0, 0])

    const res = await this.library.combat.initiative(1, 5, -2)

    // Initiative is roll + modifier (12 dex = +1) + penalty/bonus passed in (-2) + bonus (5)
    expect(res).to.eq(10 + 1 - 2 + 5)
  })

  it.only('basicFullAttack', async function () {
    const weaponId = 25 // battle axe
  })
})
