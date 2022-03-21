import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { baseType, goodsType, weaponType } from '../util/crafting'
import { randomId } from '../util'
import { RarityCrafting, RarityCraftingTools__factory } from '../../typechain/core'
import { Rarity__factory } from '../../typechain/library'
import { fakeRarity } from '../util/fakes'

chai.use(smock.matchers)

describe('Core: Common Artisan\'s Tools', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.crafter = randomId()

    this.codex = {
      commonTools: await (await smock.mock('contracts/codex/codex-items-tools.sol:codex')).deploy()
    }

    this.rarity = await fakeRarity()

    this.crafting = {
      common: await smock.fake<RarityCrafting>('contracts/core/rarity_crafting_common.sol:rarity_crafting', { 
        address: '0xf41270836dF4Db1D28F7fd0935270e3A603e78cC' 
      }),
      commonTools: await(await smock.mock<RarityCraftingTools__factory>('contracts/core/rarity_crafting_common_tools.sol:rarity_crafting_tools', {
        libraries: {
          Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
        }
      })).deploy()
    }

    await this.crafting.commonTools.setVariable('COMMON_TOOLS_CODEX', this.codex.commonTools.address)

    this.rarity.ownerOf
    .whenCalledWith(this.crafter)
    .returns(this.signer.address)
  })

  it('accepts exchange for common items worth at least 15 gp', async function () {
    const longsword = randomId()

    this.crafting.common.get_item_cost
    .whenCalledWith(baseType.weapon, weaponType.longsword)
    .returns(ethers.utils.parseEther('15'))

    this.crafting.common.items
    .whenCalledWith(longsword)
    .returns([baseType.weapon, weaponType.longsword, 0, this.crafter])

    this.crafting.common.ownerOf
    .whenCalledWith(longsword)
    .returns(this.signer.address)

    const tools = await this.crafting.commonTools.next_token()
    expect(await this.crafting.common.ownerOf(longsword)).to.eq(this.signer.address)
    await this.crafting.commonTools.exchange(this.crafter, longsword)
    expect(await this.crafting.commonTools.ownerOf(tools)).to.eq(this.signer.address)
    expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.signer.address,
      '0x000000000000000000000000000000000000dEaD',
      longsword
    )
  })

  it('rejects exchange for cheap common items', async function () {
    const crowbar = randomId()

    this.crafting.common.get_item_cost
    .whenCalledWith(baseType.goods, goodsType.crowbar)
    .returns(ethers.utils.parseEther('2'))

    this.crafting.common.items
    .whenCalledWith(crowbar)
    .returns([baseType.goods, goodsType.crowbar, 0, this.crafter])

    this.crafting.common.ownerOf
    .whenCalledWith(crowbar)
    .returns(this.signer.address)

    expect(await this.crafting.common.ownerOf(crowbar)).to.eq(this.signer.address)
    await expect(this.crafting.commonTools.exchange(this.crafter, crowbar)).revertedWith('! >= 3*tools_cost')
    expect(await this.crafting.common.ownerOf(crowbar)).to.eq(this.signer.address)
  })

})