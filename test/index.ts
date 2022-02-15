import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { craftingBaseType, weaponType, goodsType, armorType } from './api/crafting'
import { parseEther } from 'ethers/lib/utils'
import { mockCrafter, mockMasterwork, mockRarity, mockCommonItem } from './api/mocks'

describe('RarityMasterwork', function () {
  before(async function() {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.rarity = await mockRarity()
    this.masterwork = await mockMasterwork(this.rarity)
    this.crafter = await mockCrafter(this.rarity, this.signer)
  })

  it('exchanges common items for common artisan tools', async function () {
    await this.rarity.core.approve(this.masterwork.commonTools.address, this.crafter)
    const crowbar = await mockCommonItem(craftingBaseType.goods, goodsType.crowbar, this.crafter, this.rarity, this.signer)
    const longsword = await mockCommonItem(craftingBaseType.weapon, weaponType.longsword, this.crafter, this.rarity, this.signer)
    await this.rarity.crafting.approve(this.masterwork.commonTools.address, crowbar)
    await this.rarity.crafting.approve(this.masterwork.commonTools.address, longsword)

    const tools = await this.masterwork.commonTools.nextToken()
    expect(await this.rarity.crafting.ownerOf(longsword)).to.eq(this.signer.address)
    await expect(this.masterwork.commonTools.exchange(this.crafter, crowbar)).to.be.reverted
    await this.masterwork.commonTools.exchange(this.crafter, longsword)
    expect(await this.masterwork.commonTools.ownerOf(tools)).to.eq(this.signer.address)
    await expect(this.masterwork.commonTools.exchange(this.crafter, longsword)).to.be.reverted
    expect(await this.rarity.crafting.ownerOf(longsword)).to.not.eq(this.signer.address)
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

  it.only('fights a kobold', async function () {
    const longsword = await mockCommonItem(craftingBaseType.weapon, weaponType.longsword, this.crafter, this.rarity, this.signer)
    const leatherArmor = await mockCommonItem(craftingBaseType.armor, armorType.leather, this.crafter, this.rarity, this.signer)

    await this.masterwork.barn.setVariable('itemContracts', { [this.rarity.crafting.address]: {
      theContract: this.rarity.crafting.address,
      isMasterwork: false
    }})

    await expect(this.masterwork.barn.enter(this.crafter, longsword, this.rarity.crafting.address, longsword, this.rarity.crafting.address)).to.be.revertedWith("!armor")

    await this.masterwork.barn.enter(this.crafter, longsword, this.rarity.crafting.address, leatherArmor, this.rarity.crafting.address)
    expect(await this.masterwork.barn.ownerOf(1)).to.eq(this.signer.address)
    expect(await this.masterwork.barn.isWon(1)).to.eq(false)
    expect(await this.masterwork.barn.isEnded(1)).to.eq(false)

    console.log('this kobold', await this.masterwork.barn.kobolds(1))

  })

})
