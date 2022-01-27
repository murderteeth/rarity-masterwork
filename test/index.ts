import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { craftingBaseType, weaponType } from './api/crafting'
import { parseEther } from 'ethers/lib/utils'
import { mockCrafter, mockMasterwork, mockRarity } from './api/mocks'

describe('RarityMasterwork', function () {
  before(async function() {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.rarity = await mockRarity()
    this.masterwork = await mockMasterwork(this.rarity)
    this.crafter = await mockCrafter(this.rarity, this.signer)
  })

  it('crafts masterwork swords', async function () {
    const longsword = await this.rarity.crafting.next_item()
    await this.rarity.core.approve(this.rarity.crafting.address, this.crafter)
    await this.rarity.gold.approve(this.crafter, await this.rarity.crafting.SUMMMONER_ID(), parseEther('15'))
    while(true) {
      await this.rarity.mats.approve(this.crafter, await this.rarity.crafting.SUMMMONER_ID(), 100)
      await (await this.rarity.crafting.craft(this.crafter, craftingBaseType.weapon, weaponType.longsword, 100)).wait()
      if(!(await this.rarity.crafting.next_item()).eq(longsword)) break
      await network.provider.send('evm_mine')
    }

    const cost = await this.masterwork.rawMaterialCost(longsword)
    await this.rarity.core.approve(this.masterwork.address, this.crafter)
    await this.rarity.crafting.approve(this.masterwork.address, this.crafter)
    await this.rarity.gold.approve(this.crafter, await this.masterwork.APPRENTICE(), parseEther(cost.toString()))
    const tokenId = await this.masterwork.nextToken()
    await (await this.masterwork.start(this.crafter, longsword)).wait()

    expect(await this.rarity.crafting.balanceOf(this.signer.address)).to.eq(0)
    expect(await this.masterwork.balanceOf(this.signer.address)).to.eq(1)
    expect(await this.masterwork.ownerOf(tokenId)).to.eq(this.signer.address)
    expect((await this.masterwork.components(tokenId)).crafter).to.eq(0)

    {
      const [m, n] = await this.masterwork.progress(tokenId)
      expect(m.div(n)).to.eq(0)
    }

    const xpBefore = await this.rarity.core.xp(this.crafter)
    while(true) {
      await this.masterwork.craft(tokenId, 0)
      const project = await this.masterwork.projects(tokenId)
      if(project.complete) break
      await network.provider.send('evm_mine')
    }

    expect(await this.rarity.crafting.balanceOf(this.signer.address)).to.eq(1)
    expect(await this.rarity.crafting.tokenOfOwnerByIndex(this.signer.address, 0)).to.eq(longsword)
    expect((await this.masterwork.components(tokenId)).crafter).to.eq(this.crafter)

    const xpAfter = await this.rarity.core.xp(this.crafter)
    const xpCost = xpBefore.sub(xpAfter)
    expect(xpCost.gt(0)).to.be.true

  })

})
