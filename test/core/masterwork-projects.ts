import chai, { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { ethers } from 'hardhat'
import isSvg from 'is-svg'
import { clean, humanEther } from '../../util'
import { RarityCraftingMaterials2 } from '../../typechain/core/RarityCraftingMaterials2'
import { armorType, baseType, toolType, weaponType } from '../../util/crafting'
import { Attributes__factory, Crafting__factory, Feats__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { fakeAttributes, fakeCommonCrafting, fakeCraftingSkills, fakeCraftingSkillsCodex, fakeGold, fakeMasterworkTools, fakeRandom, fakeRarity, fakeSkills, fakeSummoner } from '../../util/fakes'
import { skills, skillsArray } from '../../util/skills'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { armors, weapons } from '../../util/equipment'
import devAddresses from '../../addresses.dev.json'
import { MasterworkUri__factory, RarityMasterworkItems, RarityMasterworkProjects__factory } from '../../typechain/core'

chai.use(smock.matchers)

describe('Core: Crafting II - Masterwork Projects', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]
    this.mats = await smock.fake<RarityCraftingMaterials2>(
      'contracts/core/rarity_crafting-materials-2.sol:rarity_crafting_materials_2',
      { address: devAddresses.core_rarity_crafting_mats_2 }
    )

    this.core = {
      rarity: await fakeRarity(),
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      crafting: await fakeCommonCrafting(),
      craftingSkills: await fakeCraftingSkills(),
      gold: await fakeGold()
    }

    this.codex = {
      random: await fakeRandom(),
      craftingSkills: await fakeCraftingSkillsCodex(),
      common: {
        tools: await smock.fake('contracts/codex/codex-items-tools.sol:codex'),
      },
      masterwork: {
        weapons: await smock.fake('contracts/codex/codex-items-weapons-masterwork.sol:codex', { address: devAddresses.codex_weapons_masterwork }),
        armor: await smock.fake('contracts/codex/codex-items-armor-masterwork.sol:codex', { address: devAddresses.codex_armor_masterwork }),
        tools: await smock.fake('contracts/codex/codex-items-tools-masterwork.sol:codex', { address: devAddresses.codex_tools_masterwork })
      }
    }

    this.masterwork = {
      items: await smock.fake<RarityMasterworkItems>('contracts/core/rarity_crafting_masterwork_items.sol:rarity_masterwork_items', { address: devAddresses.core_masterwork_items }),
      projects: await(await smock.mock<RarityMasterworkProjects__factory>('contracts/core/rarity_crafting_masterwork_projects.sol:rarity_masterwork_projects', {
        libraries: {
          Crafting: (await (await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address,
          CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address,
          masterwork_uri: (await(await smock.mock<MasterworkUri__factory>('contracts/core/rarity_crafting_masterwork_uri.sol:masterwork_uri')).deploy()).address,
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
          Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address
        }
      })).deploy()
    }

    this.core.gold.transferFrom.returns(true)

    this.core.crafting.get_item_cost
    .whenCalledWith(baseType.weapon, weaponType.longsword)
    .returns(ethers.utils.parseEther('15'))

    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.dagger)
    .returns({...weapons('dagger', true), id: weaponType.dagger})
    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns({...weapons('longsword', true), id: weaponType.longsword})
    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.nunchaku)
    .returns({...weapons('nunchaku', true), id: weaponType.nunchaku})
    this.codex.masterwork.armor.item_by_id
    .whenCalledWith(armorType.fullPlate)
    .returns({...armors('full plate', true), id: armorType.fullPlate})

    this.codex.masterwork.tools.item_by_id
    .whenCalledWith(toolType.artisanTools)
    .returns([toolType.artisanTools, 5, ethers.utils.parseEther('55'), "Masterwork Artisan's Tools", "", skillsArray({ index: skills.craft, ranks: 2})])
    this.codex.masterwork.tools.get_skill_bonus
    .whenCalledWith(toolType.artisanTools, 6)
    .returns(2)
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

  it('starts crafting projects with rented tools', async function() {
    const token = await this.masterwork.projects.next_token()
    const apprentice = await this.masterwork.projects.APPRENTICE()
    const rawMaterials = await this.masterwork.projects.raw_materials_cost(baseType.weapon, weaponType.longsword)
    const toolRental = await this.masterwork.projects.COMMON_ARTISANS_TOOLS_RENTAL()
    const cost = rawMaterials.add(toolRental);

    this.core.gold.transferFrom
    .whenCalledWith(apprentice, this.crafter, apprentice, cost)
    .returns(true)

    await expect(this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0))
    .to.emit(this.masterwork.projects, 'Transfer')
    .withArgs(ethers.constants.AddressZero, this.signer.address, token)

    expect(this.core.gold.transferFrom)
    .to.have.been.calledWith(apprentice, this.crafter, apprentice, cost)

    const project = await this.masterwork.projects.projects(token)
    expect(project.base_type).to.eq(baseType.weapon)
    expect(project.item_type).to.eq(weaponType.longsword)
    expect(project.tools).to.eq(0)
    expect(project.started).to.be.gt(0)
  })

  it('starts crafting projects with masterwork tools', async function(){
    const tools = await fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    const apprentice = await this.masterwork.projects.APPRENTICE()
    const cost = await this.masterwork.projects.raw_materials_cost(baseType.weapon, weaponType.longsword)

    this.core.gold.transferFrom
    .whenCalledWith(apprentice, this.crafter, apprentice, cost)
    .returns(true)

    await expect(this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools))
    .to.emit(this.masterwork.projects, 'Transfer')
    .withArgs(ethers.constants.AddressZero, this.signer.address, token)

    expect(this.masterwork.items['safeTransferFrom(address,address,uint256)'])
    .to.have.been.calledWith(this.signer.address, this.masterwork.projects.address, tools)

    expect(this.core.gold.transferFrom)
    .to.have.been.calledWith(apprentice, this.crafter, apprentice, cost)

    const project = await this.masterwork.projects.projects(token)
    expect(project.base_type).to.eq(baseType.weapon)
    expect(project.item_type).to.eq(weaponType.longsword)
    expect(project.tools).to.eq(tools)
    expect(project.started).to.be.gt(0)
  })

  it('validates item type', async function() {
    expect(await this.masterwork.projects.valid_item_type(0, 0)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(1, 1)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(2, 1)).to.be.true
    expect(await this.masterwork.projects.valid_item_type(3, 1)).to.be.true
    expect(await this.masterwork.projects.valid_item_type(4, 1)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(5, 1)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(4, 2)).to.be.true
    expect(await this.masterwork.projects.valid_item_type(2, 19)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(3, 60)).to.be.false
    expect(await this.masterwork.projects.valid_item_type(4, 12)).to.be.false
  })

  it('checks crafter eligibility', async function(){
    const crafter = fakeSummoner(this.core.rarity, this.signer);
    expect(await this.masterwork.projects.eligible(crafter)).to.be.false

    const skillsRanks = Array(36).fill(0)
    skillsRanks[skills.craft] = 1
    this.core.skills.get_skills
    .whenCalledWith(crafter)
    .returns(skillsRanks)
    expect(await this.masterwork.projects.eligible(crafter)).to.be.true
  })

  it('computes raw materials cost', async function() {
    {
      const cost = await this.masterwork.projects.raw_materials_cost(baseType.weapon, weaponType.longsword)
      expect(humanEther(cost).toFixed(1)).to.eq(((15 + 300) / 3).toFixed(1))
    }
    {
      const cost = await this.masterwork.projects.raw_materials_cost(baseType.armor, armorType.fullPlate)
      expect(humanEther(cost).toFixed(1)).to.eq(((1500 + 150) / 3).toFixed(1))
    }
    {
      const cost = await this.masterwork.projects.raw_materials_cost(baseType.tools, toolType.artisanTools)
      expect(humanEther(cost).toFixed(1)).to.eq((55 / 3).toFixed(1))
    }
  })

  it('takes no craft penalty when using rented tools', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    expect(await this.masterwork.projects.craft_bonus(token, 0)).to.eq(0)
  })

  it('gives a +2 craft bonus when using masterwork tools', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)
    expect(await this.masterwork.projects.craft_bonus(token, 0)).to.eq(2)
  })

  it('gives a 1/20 craft bonus for bonus mats', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    expect(await this.masterwork.projects.craft_bonus(token, ethers.utils.parseEther('80'))).to.eq(4)
  })

  it('puts a ceiling on bonus mats', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    const maxMats = await this.masterwork.projects.max_bonus_mats(token)
    expect(await this.masterwork.projects.craft_bonus(token, maxMats)).to.eq(127)
    expect(await this.masterwork.projects.craft_bonus(token, maxMats.add(ethers.utils.parseEther('100')))).to.eq(127)
  })

  it('burns bonus mats when crafting', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    await this.masterwork.projects.craft(token, ethers.utils.parseEther('80'))
    expect(this.mats.burn).to.have.been.calledWith(this.signer.address, ethers.utils.parseEther('80'))
  })

  it('computes standard component dc', async function() {
    expect(await this.masterwork.projects.standard_component_dc(baseType.weapon, weaponType.dagger))
    .to.eq(12)

    expect(await this.masterwork.projects.standard_component_dc(baseType.weapon, weaponType.longsword))
    .to.eq(15)

    expect(await this.masterwork.projects.standard_component_dc(baseType.weapon, weaponType.nunchaku))
    .to.eq(18)

    expect(await this.masterwork.projects.standard_component_dc(baseType.armor, armorType.fullPlate))
    .to.eq(18)

    expect(await this.masterwork.projects.standard_component_dc(baseType.tools, toolType.artisanTools))
    .to.eq(15)
  })

  it('uses masterwork dc after standard component is complete', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.setVariable('projects', {
      [token]: {
        complete: false,
        base_type: baseType.weapon,
        item_type: weaponType.longsword,
        progress: 0,
        started: 1,
        tools: 0,
        xp: 0
      }
    })
    expect(await this.masterwork.projects['get_dc(uint256)'](token)).to.eq(15)

    await this.masterwork.projects.setVariable('projects', {
      [token]: {
        complete: false,
        base_type: baseType.weapon,
        item_type: weaponType.longsword,
        progress: await this.masterwork.projects.standard_component_cost_in_silver(baseType.weapon, weaponType.longsword),
        started: 1,
        tools: 0,
        xp: 0
      }
    })
    expect(await this.masterwork.projects['get_dc(uint256)'](token)).to.eq(20)
  })

  it('gets craft check odds', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    await this.masterwork.projects.setVariable('projects', { [token]: {
      ...clean({...await this.masterwork.projects.projects(token)}), progress: 0
    }})

    const [average_score, dc] = await this.masterwork.projects.get_craft_check_odds(token, ethers.utils.parseEther('20'))
    expect(average_score).to.eq(25)
    expect(dc).to.eq(15)
  })

  it('estimates project xp cost', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    const xp = await this.masterwork.projects.estimate_remaining_xp_cost(token, ethers.utils.parseEther('20'))
    expect(xp).to.deep.eq(ethers.utils.parseEther('1260'))
  })

  it('passes craft checks and makes progress', async function() {
    this.codex.random.dn.returns(20)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    await expect(this.masterwork.projects.craft(token, 0))
    .to.emit(this.masterwork.projects, 'Craft')
    .withArgs(
      this.signer.address, token, this.crafter, 0, 
      20, 34, 
      ethers.utils.parseEther('250'), 
      ethers.utils.parseEther('510'), ethers.utils.parseEther('3150')
    )
  })

  it('fails craft checks and doesn\'t make progress', async function() {
    this.codex.random.dn.returns(1)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.nunchaku, 0)
    await expect(this.masterwork.projects.craft(token, 0))
    .to.emit(this.masterwork.projects, 'Craft')
    .withArgs(
      this.signer.address, token, this.crafter, 0, 
      1, 15, 
      ethers.utils.parseEther('250'), 
      0, ethers.utils.parseEther('3020')
    )
  })

  it('crafts until complete', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    const costInSilver = await this.masterwork.projects.item_cost_in_silver(baseType.weapon, weaponType.longsword)

    let project = await this.masterwork.projects.projects(token)
    const almostDone = costInSilver.sub(ethers.utils.parseEther('10'))
    await this.masterwork.projects.setVariable('projects', { [token]: {
      ...clean({...project}), progress: almostDone
    }})

    this.codex.random.dn.returns(20)
    await this.masterwork.projects.craft(token, 0)

    project = await this.masterwork.projects.projects(token)
    expect(project.complete).to.be.true

    const xpPerDay = ethers.utils.parseEther('250')
    const expectedScoreTimesDc = ethers.utils.parseEther('680')
    const prorateXp = (costInSilver.sub(almostDone)).mul(xpPerDay).div(expectedScoreTimesDc)
    expect(this.core.rarity.spend_xp)
    .to.be.calledWith(this.crafter, prorateXp)
  })

  it('can\'t craft if crafting is complete', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)

    {
      const project = await this.masterwork.projects.projects(token)
      const [, costInSilver] = await this.masterwork.projects['get_progress(uint256)'](token)
      const progress = Math.floor((humanEther(costInSilver) / 20))
      await this.masterwork.projects.setVariable('projects', { [token]: {
        ...clean({...project}), complete: true
      }})
    }

    await expect(this.masterwork.projects.craft(token, 0))
    .to.be.revertedWith('complete')
  })

  it('reclaims tools from complete projects', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)

    const project = await this.masterwork.projects.projects(token)
    await this.masterwork.projects.setVariable('projects', { [token]: {
      ...clean({...project}), complete: true
    }})

    await this.masterwork.projects.reclaim_tools(token)
    expect(this.masterwork.items['safeTransferFrom(address,address,uint256)'])
    .to.have.been.calledWith(this.masterwork.projects.address, this.signer.address, tools)
  })

  it('can\'t reclaim tools from incomplete projects', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)
    await expect(this.masterwork.projects.reclaim_tools(token))
    .to.be.revertedWith('!complete')
  })

  it('cancels incomplete projects', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)
    await this.masterwork.projects.cancel(token)
    expect(this.masterwork.items['safeTransferFrom(address,address,uint256)'])
    .to.have.been.calledWith(this.masterwork.projects.address, this.signer.address, tools)
  })

  it('cancels complete projects that have been claimed', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)

    const project = await this.masterwork.projects.projects(token)
    await this.masterwork.projects.setVariable('projects', { [token]: {
      ...clean({...project}), complete: true
    }})

    this.masterwork.items.claims
    .whenCalledWith(token)
    .returns(true)

    await this.masterwork.projects.cancel(token)
    expect(this.masterwork.items['safeTransferFrom(address,address,uint256)'])
    .to.have.been.calledWith(this.masterwork.projects.address, this.signer.address, tools)
  })

  it('can\'t cancel complete projects that haven\'t been claimed', async function() {
    const tools = fakeMasterworkTools(this.masterwork.items, this.crafter, this.signer)
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, tools)

    const project = await this.masterwork.projects.projects(token)
    await this.masterwork.projects.setVariable('projects', { [token]: {
      ...clean({...project}), complete: true
    }})

    await expect(this.masterwork.projects.cancel(token))
    .to.be.revertedWith('!claimed')
  })

  it('makes valid token uris', async function() {
    const token = await this.masterwork.projects.next_token()
    await this.masterwork.projects.start(this.crafter, baseType.weapon, weaponType.longsword, 0)
    const tokenUri = await this.masterwork.projects.tokenURI(token)
    const tokenJson = JSON.parse(Buffer.from(tokenUri.split(',')[1], "base64").toString());
    const tokenSvg = Buffer.from(tokenJson.image.split(',')[1], "base64").toString();
    // console.log('tokenJson.image', tokenJson.image)
    expect(isSvg(tokenSvg)).to.be.true;
  })
})