import { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { craftingBaseType, weaponType, goodsType, armorType } from './api/crafting'
import { parseEther } from 'ethers/lib/utils'
import { mockCrafter, mockMasterwork, mockRarity, mockCommonItem, mockMasterworkProject, useRandomMock, mockCommonTools } from './api/mocks'

describe('RarityMasterwork', function () {
  before(async function() {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.rarity = await mockRarity()
    this.masterwork = await mockMasterwork(this.rarity)
    this.crafter = await mockCrafter(this.rarity, this.signer)
  })

  it.only('exchanges common items for common artisan tools', async function () {
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

  it.only('reduces bonus by -2 when crafting with "improvised" tools', async function () {
    const project = await mockMasterworkProject(
      this.crafter, craftingBaseType.weapon, weaponType.longsword, 0, '0x0000000000000000000000000000000000000000', this.masterwork)
    const craftingBonus = (await this.masterwork.projects.craftingBonus(project, 0)).toNumber()
    expect(craftingBonus).to.eq(10)
  })

  it.only('gives no bonus when crafting with common tools', async function () {
    const tools = await mockCommonTools(this.crafter, this.masterwork, this.signer)
    const project = await mockMasterworkProject(
      this.crafter, craftingBaseType.weapon, weaponType.longsword,
      tools.toNumber(), this.masterwork.commonTools.address, this.masterwork)
    const craftingBonus = (await this.masterwork.projects.craftingBonus(project, 0)).toNumber()
    expect(craftingBonus).to.eq(12)
  })

  it('improves bonus by +2 when crafting with masterwork tools', async function () {
    expect(false)
  })

  it('makes no progress if you fail a craft check', async function () {
    const craftBonus = (await this.masterwork.projects.craftBonus(this.crafter, 0)).toNumber()
    const highestRollThatStillFails = 20 - (craftBonus + 1)
    useRandomMock(this, this.rarity.crafting, '_random', highestRollThatStillFails, async () => {
      await this.rarity.core.approve(this.masterwork.projects.address, this.crafter)
      const project = await mockMasterworkProject(this.crafter, craftingBaseType.weapon, weaponType.longsword, 0, '0x0000000000000000000000000000000000000000', this.masterwork)
      const tx = await(await this.masterwork.projects.craft(project, 0)).wait()
      const { check, m } = tx.events[0].args
      expect(check).to.eq(19)
      expect(m).to.eq(0)
    })
  })

  // it('breaks your common artisan tools if you crit fail a craft check', async function () {
  //   await this.rarity.random.setVariable('__mock_enabled', true)
  //   await this.rarity.random.setVariable('__mock_result', 20)
  //   await this.rarity.crafting.setVariable('_random', this.rarity.random.address)

  //   await this.rarity.core.approve(this.masterwork.projects.address, this.crafter)
  //   const project = await mockMasterworkProject(craftingBaseType.weapon, weaponType.longsword, this.crafter, this.masterwork)
  //   const tx = await(await this.masterwork.projects.craft(project, 0)).wait()
  //   const { check } = tx.events[0].args
  //   // console.log('check', check)

  // })

  it('crafts masterwork swords', async function () {
    const cost = await this.masterwork.projects.getRawMaterialCost(craftingBaseType.weapon, weaponType.longsword)
    await this.rarity.core.approve(this.masterwork.projects.address, this.crafter)
    await this.rarity.gold.approve(this.crafter, await this.masterwork.projects.APPRENTICE(), parseEther(cost.toString()))
    const startTx = await(await this.masterwork.projects.start(this.crafter, craftingBaseType.weapon, weaponType.longsword)).wait()
    const projectId = startTx.events[3].args.tokenId

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

    const claimTx = await(await this.masterwork.items.claim(projectId)).wait()
    const itemId = claimTx.events[0].args.tokenId

    await expect(this.masterwork.items.claim(projectId)).to.be.reverted
    expect(await this.masterwork.items.ownerOf(itemId)).to.eq(this.signer.address)

    const longsword = await this.masterwork.items.items(itemId)
    expect(longsword.baseType).to.eq(craftingBaseType.weapon)
    expect(longsword.itemType).to.eq(weaponType.longsword)
    expect(longsword.crafter).to.eq(this.crafter)
  })

  it.only('fights a kobold', async function () {
    const longsword = await mockCommonItem(craftingBaseType.weapon, weaponType.longsword, this.crafter, this.rarity, this.signer)
    const leatherArmor = await mockCommonItem(craftingBaseType.armor, armorType.leather, this.crafter, this.rarity, this.signer)

    this.rarity.fakeCore.ownerOf.whenCalledWith(1).returns(this.signer.address)
    this.rarity.fakeCore.level.returns(5)
    this.rarity.fakeCore.class.returns(1)

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
