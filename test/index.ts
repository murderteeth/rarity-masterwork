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
    const cost = await this.masterwork.projects.getRawMaterialCost(craftingBaseType.weapon, weaponType.longsword)
    await this.rarity.core.approve(this.masterwork.projects.address, this.crafter)
    await this.rarity.gold.approve(this.crafter, await this.masterwork.projects.APPRENTICE(), parseEther(cost.toString()))
    await this.masterwork.projects.start(this.crafter, craftingBaseType.weapon, weaponType.longsword)
    const projectId = await this.masterwork.projects.tokenOfOwnerByIndex(this.crafter, 0)

    expect(await this.masterwork.projects.balanceOf(this.crafter)).to.eq(1)
    expect(await this.masterwork.items.balanceOf(this.signer.address)).to.eq(0)
    {
      const [m, n] = await this.masterwork.projects.progress(projectId)
      expect(m.div(n)).to.eq(0)
    }

    const xpBefore = await this.rarity.core.xp(this.crafter)
    while(true) {
      await this.masterwork.projects.craft(projectId, 0)
      const project = await this.masterwork.projects.projects(projectId)
      if(project.completed > 0) break
      await network.provider.send('evm_mine')
    }

    const xpAfter = await this.rarity.core.xp(this.crafter)
    const xpCost = xpBefore.sub(xpAfter)
    expect(xpCost.gt(0)).to.be.true

    await this.masterwork.items.claim(projectId)
    await expect(this.masterwork.items.claim(projectId)).to.be.reverted
    expect(await this.masterwork.items.balanceOf(this.signer.address)).to.eq(1)

    const longsword = await this.masterwork.items.itemOfOwnerByIndex(this.signer.address, 0)
    expect(longsword.baseType).to.eq(craftingBaseType.weapon)
    expect(longsword.itemType).to.eq(weaponType.longsword)
    expect(longsword.crafter).to.eq(this.crafter)

  })

})
