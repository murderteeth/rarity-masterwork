import chai, { expect } from 'chai'
import { MockContract, smock } from '@defi-wonderland/smock'
import { ethers } from 'hardhat'
import { clean, humanEther } from '../util'
import { RarityCraftingMaterials2 } from '../../typechain/core/RarityCraftingMaterials2'
import { RarityMasterwork__factory } from '../../typechain/core/factories/RarityMasterwork__factory'
import { armorType, baseType, toolType, weaponType } from '../util/crafting'
import { Attributes__factory, Crafting__factory, Feats__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { fakeAttributes, fakeCommonCrafting, fakeCraftingSkills, fakeCraftingSkillsCodex, fakeGold, fakeRandom, fakeRarity, fakeSkills, fakeSummoner } from '../util/fakes'
import { skills, skillsArray } from '../util/skills'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { RarityCrafting } from '../../typechain/core'

chai.use(smock.matchers)

describe('Core: Crafting II - Masterwork', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.mats = await smock.fake<RarityCraftingMaterials2>('contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2')

    this.core = {
      rarity: await fakeRarity(),
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      craftingSkills: await fakeCraftingSkills(),
      commonCrafting: (await (await smock.mock<RarityCrafting>('contracts/core/rarity_crafting_common.sol:rarity_crafting')).deploy()).address,
      gold: await fakeGold()
    }

    this.codex = {
      random: await fakeRandom(),
      craftingSkills: await fakeCraftingSkillsCodex(),
      masterwork: {
        armor: await smock.fake('contracts/codex/codex-items-armor-masterwork.sol:codex'),
        tools: await smock.fake('contracts/codex/codex-items-tools-masterwork.sol:codex'),
        weapons: await smock.fake('contracts/codex/codex-items-weapons-masterwork.sol:codex')
      }
    }

    this.masterwork = await(await smock.mock<RarityMasterwork__factory>('contracts/core/rarity_crafting_masterwork.sol:rarity_masterwork', {
      libraries: {
        Crafting: (await (await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address,
        Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
        Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
            Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
            CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
          }
        })).deploy()).address,
        Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
        CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
      }
    })).deploy()

    this.core.gold.transferFrom.returns(true)

    await this.masterwork.setVariable('BONUS_MATS', this.mats.address)
    await this.masterwork.setVariable('ARMOR_CODEX', this.codex.masterwork.armor.address)
    await this.masterwork.setVariable('TOOLS_CODEX', this.codex.masterwork.tools.address)
    await this.masterwork.setVariable('WEAPONS_CODEX', this.codex.masterwork.weapons.address)

    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns([weaponType.longsword, 2, 3, 3, 4, 8, 2, -1, 0, ethers.utils.parseEther('315'), "Masterwork Longsword", ""])

    this.codex.masterwork.armor.item_by_id
    .whenCalledWith(armorType.fullPlate)
    .returns([armorType.fullPlate, 3, 50, 8, 1, -6, 35, ethers.utils.parseEther('1650'), "Masterwork Full plate", ""])

    this.codex.masterwork.tools.item_by_id
    .whenCalledWith(toolType.artisanTools)
    .returns([toolType.artisanTools, 5, ethers.utils.parseEther('55'), "Masterwork Artisan's Tools", "", skillsArray({ index: skills.craft, ranks: 2})])
  })

  this.beforeEach(async function() {
    this.crafter = fakeSummoner(this.core.rarity, this.signer);
    this.core.rarity.level
    .whenCalledWith(this.crafter)
    .returns(6)
    this.core.attributes.ability_scores
    .whenCalledWith(this.crafter)
    .returns([0, 0, 0, 20, 0, 0])
    const skillsRanks = Array(36).fill(0)
    skillsRanks[skills.craft] = 9
    this.core.skills.get_skills
    .whenCalledWith(this.crafter)
    .returns(skillsRanks)
  })

  async function mockMasterworkTools(masterwork: MockContract, signer: SignerWithAddress) {
    const tools = await masterwork.next_token()
    const balance = await masterwork.balanceOf(signer.address)
    await masterwork.setVariable('items', {
      [tools.toNumber()]: {
        base_type: 4,
        item_type: 2,
        crafted: 0,
        crafter: 0
      }
    })
    await masterwork.setVariable('_owners', {
      [tools.toNumber()]: signer.address
    })
    await masterwork.setVariable('_balances', {
      [signer.address]: balance.add(1)
    })
    await masterwork.setVariable('next_token', tools.add(1))
    await masterwork.approve(masterwork.address, tools)
    return tools
  }

  it('starts crafting projects with masterwork tools', async function(){
    const tools = await mockMasterworkTools(this.masterwork, this.signer)
    const token = await this.masterwork.next_token()
    const apprentice = await this.masterwork.APPRENTICE()
    const cost = await this.masterwork.raw_materials_cost(baseType.weapon, weaponType.longsword)

    this.core.gold.transferFrom
    .whenCalledWith(apprentice, this.crafter, apprentice, cost)
    .returns(true)

    await expect(this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, tools, this.masterwork.address))
    .to.emit(this.masterwork, 'Transfer')
    .withArgs(ethers.constants.AddressZero, this.signer.address, token)

    expect(await this.masterwork.ownerOf(tools)).to.eq(this.masterwork.address)
    expect(await this.masterwork.getApproved(tools)).to.eq(this.signer.address)

    expect(this.core.gold.transferFrom)
    .to.have.been.calledWith(apprentice, this.crafter, apprentice, cost)

    const project = await this.masterwork.projects(token)
    expect(project.base_type).to.eq(baseType.weapon)
    expect(project.item_type).to.eq(weaponType.longsword)
    expect(project.tools).to.eq(tools)
    expect(project.started).to.be.gt(0)
  })

  it('starts crafting projects with rented tools', async function() {
    const token = await this.masterwork.next_token()
    const apprentice = await this.masterwork.APPRENTICE()
    const rawMaterials = await this.masterwork.raw_materials_cost(baseType.weapon, weaponType.longsword)
    const toolRental = await this.masterwork.COMMON_ARTISANS_TOOLS_RENTAL()
    const cost = rawMaterials.add(toolRental);

    this.core.gold.transferFrom
    .whenCalledWith(apprentice, this.crafter, apprentice, cost)
    .returns(true)

    await expect(this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero))
    .to.emit(this.masterwork, 'Transfer')
    .withArgs(ethers.constants.AddressZero, this.signer.address, token)

    expect(this.core.gold.transferFrom)
    .to.have.been.calledWith(apprentice, this.crafter, apprentice, cost)

    const project = await this.masterwork.projects(token)
    expect(project.base_type).to.eq(baseType.weapon)
    expect(project.item_type).to.eq(weaponType.longsword)
    expect(project.tools).to.eq(0)
    expect(project.started).to.be.gt(0)
  })

  it('validates item type', async function() {
    expect(await this.masterwork.valid_item_type(0, 0)).to.be.false
    expect(await this.masterwork.valid_item_type(1, 1)).to.be.false
    expect(await this.masterwork.valid_item_type(2, 1)).to.be.true
    expect(await this.masterwork.valid_item_type(3, 1)).to.be.true
    expect(await this.masterwork.valid_item_type(4, 1)).to.be.true
    expect(await this.masterwork.valid_item_type(5, 1)).to.be.false
    expect(await this.masterwork.valid_item_type(2, 19)).to.be.false
    expect(await this.masterwork.valid_item_type(3, 60)).to.be.false
    expect(await this.masterwork.valid_item_type(4, 12)).to.be.false
  })

  it('checks crafter eligibility', async function(){
    const crafter = fakeSummoner(this.core.rarity, this.signer);
    expect(await this.masterwork.eligible(crafter)).to.be.false

    const skillsRanks = Array(36).fill(0)
    skillsRanks[skills.craft] = 1
    this.core.skills.get_skills
    .whenCalledWith(crafter)
    .returns(skillsRanks)
    expect(await this.masterwork.eligible(crafter)).to.be.true
  })

  it('computes raw materials cost', async function() {
    {
      const cost = await this.masterwork.raw_materials_cost(baseType.weapon, weaponType.longsword)
      expect(humanEther(cost).toFixed(1)).to.eq(((15 + 300) / 3).toFixed(1))
    }
    {
      const cost = await this.masterwork.raw_materials_cost(baseType.armor, armorType.fullPlate)
      expect(humanEther(cost).toFixed(1)).to.eq(((1500 + 150) / 3).toFixed(1))
    }
    {
      const cost = await this.masterwork.raw_materials_cost(baseType.tools, toolType.artisanTools)
      expect(humanEther(cost).toFixed(1)).to.eq((55 / 3).toFixed(1))
    }
  })

  it('takes no craft penalty when using rented tools', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    expect(await this.masterwork.craft_bonus(token, 0)).to.eq(0)
  })

  it('gives a +2 craft bonus when using masterwork tools', async function() {
    const tools = await mockMasterworkTools(this.masterwork, this.signer)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, tools, this.masterwork.address)
    expect(await this.masterwork.craft_bonus(token, 0)).to.eq(2)
  })

  it('gives a 1/20 craft bonus for bonus mats', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    expect(await this.masterwork.craft_bonus(token, ethers.utils.parseEther('80'))).to.eq(4)
  })

  it('burns bonus mats when crafting', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    await this.masterwork.craft(token, this.crafter, ethers.utils.parseEther('80'))
    expect(this.mats.burn).to.have.been.calledWith(ethers.utils.parseEther('80'))
  })

  it('computes standard component dc', async function() {
    expect(await this.masterwork.standard_component_dc(baseType.weapon, weaponType.dagger))
    .to.eq(20)
    expect(await this.masterwork.standard_component_dc(baseType.weapon, weaponType.longsword))
    .to.eq(25)
    expect(await this.masterwork.standard_component_dc(baseType.weapon, weaponType.nunchaku))
    .to.eq(30)
    expect(await this.masterwork.standard_component_dc(baseType.armor, armorType.fullPlate))
    .to.eq(28)
    expect(await this.masterwork.standard_component_dc(baseType.tools, toolType.artisanTools))
    .to.eq(25)
  })

  it('uses masterwork dc after standard component is complete', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.setVariable('projects', {
      [token]: {
        done_crafting: false,
        complete: false,
        base_type: baseType.weapon,
        item_type: weaponType.longsword,
        progress: 0,
        started: 1,
        tools: 0,
        xp: 0
      }
    })
    expect(await this.masterwork['get_dc(uint256)'](token)).to.eq(25)

    await this.masterwork.setVariable('projects', {
      [token]: {
        done_crafting: false,
        complete: false,
        base_type: baseType.weapon,
        item_type: weaponType.longsword,
        progress: await this.masterwork.standard_component_cost_in_silver(baseType.weapon, weaponType.longsword),
        started: 1,
        tools: 0,
        xp: 0
      }
    })
    expect(await this.masterwork['get_dc(uint256)'](token)).to.eq(30)
  })

  it('passes craft checks and makes progress', async function() {
    this.codex.random.dn.returns(20)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    await expect(this.masterwork.craft(token, this.crafter, 0))
    .to.emit(this.masterwork, 'Craft')
    .withArgs(
      this.signer.address, token, this.crafter, 0, 
      20, 34, 
      ethers.utils.parseEther('250'), 
      ethers.utils.parseEther('1170'), ethers.utils.parseEther('3150')
    )
  })

  it('fails craft checks and doesn\'t make progress', async function() {
    this.codex.random.dn.returns(1)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    await expect(this.masterwork.craft(token, this.crafter, 0))
    .to.emit(this.masterwork, 'Craft')
    .withArgs(
      this.signer.address, token, this.crafter, 0, 
      1, 15, 
      ethers.utils.parseEther('250'), 
      0, ethers.utils.parseEther('3150')
    )
  })

  it('crafts until done', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)

    {
      const project = await this.masterwork.projects(token)
      await this.masterwork.setVariable('projects', { [token]: {
        ...clean({...project}), progress: await this.masterwork.item_cost_in_silver(baseType.weapon, weaponType.longsword)
      }})
    }

    this.codex.random.dn.returns(20)
    await this.masterwork.craft(token, this.crafter, 0)

    const project = await this.masterwork.projects(token)
    expect(project.done_crafting).to.be.true
  })

  it('can\'t craft if crafting is done', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)

    {
      const project = await this.masterwork.projects(token)
      const [, costInSilver] = await this.masterwork['get_progress(uint256)'](token)
      const progress = Math.floor((humanEther(costInSilver) / 20))
      await this.masterwork.setVariable('projects', { [token]: {
        ...clean({...project}), done_crafting: true
      }})
    }

    await expect(this.masterwork.craft(token, this.crafter, 0))
    .to.be.revertedWith('done_crafting')
  })

  it('completes projects', async function() {
    const tools = await mockMasterworkTools(this.masterwork, this.signer)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, tools, this.masterwork.address)

    const project = await this.masterwork.projects(token)
    await this.masterwork.setVariable('projects', { [token]: {
      ...clean({...project}), done_crafting: true
    }})

    await expect(this.masterwork.complete(token, this.crafter))
    .to.emit(this.masterwork, 'Crafted')
    .withArgs(this.signer.address, token, this.crafter, baseType.weapon, weaponType.longsword)

    expect(await this.masterwork.ownerOf(tools)).to.eq(this.signer.address)

    const item = await this.masterwork.items(token)
    expect(item.base_type).to.eq(baseType.weapon)
    expect(item.item_type).to.eq(weaponType.longsword)
    expect(item.crafted).to.be.gt(0)
    expect(item.crafter).to.eq(this.crafter)

    expect((await this.masterwork.projects(token)).complete).to.be.true
  })

  it('can\'t complete projects that are already complete', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)

    const project = await this.masterwork.projects(token)
    await this.masterwork.setVariable('projects', { [token]: {
      ...clean({...project}), done_crafting: true, complete: true
    }})
    await expect(this.masterwork.complete(token, this.crafter))
    .to.be.revertedWith('complete')
  })

  it('can\'t complete projects if crafting isn\'t done', async function() {
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, 0, ethers.constants.AddressZero)
    await expect(this.masterwork.complete(token, this.crafter))
    .to.be.revertedWith('!done_crafting')
  })

  it('cancels projects', async function() {
    const tools = await mockMasterworkTools(this.masterwork, this.signer)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, tools, this.masterwork.address)

    await expect(this.masterwork.cancel(token))
    .to.emit(this.masterwork, 'Transfer')
    .withArgs(this.signer.address, ethers.constants.AddressZero, token)

    expect(await this.masterwork.ownerOf(tools)).to.eq(this.signer.address)
  })

  it('can\'t cancel projects that are done crafting', async function() {
    const tools = await mockMasterworkTools(this.masterwork, this.signer)
    const token = await this.masterwork.next_token()
    await this.masterwork.start(this.crafter, baseType.weapon, weaponType.longsword, tools, this.masterwork.address)

    const project = await this.masterwork.projects(token)
    await this.masterwork.setVariable('projects', { [token]: {
      ...clean({...project}), done_crafting: true
    }})

    await expect(this.masterwork.cancel(token))
    .to.be.revertedWith('done_crafting')
  })
})