import chai, { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { ethers } from 'hardhat'
import isSvg from 'is-svg'
import { randomId } from '../../util'
import { baseType, weaponType } from '../../util/crafting'
import { Crafting__factory, Rarity__factory } from '../../typechain/library'
import { fakeRarity, fakeSummoner } from '../../util/fakes'
import { weapons } from '../../util/equipment'
import devAddresses from '../../addresses.dev.json'
import { MasterworkUri__factory, RarityMasterworkItems__factory, RarityMasterworkProjects } from '../../typechain/core'

chai.use(smock.matchers)

describe('Core: Crafting II - Masterwork Items', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]

    this.codex = {
      masterwork: {
        weapons: await smock.fake('contracts/codex/codex-items-weapons-masterwork.sol:codex', { address: devAddresses.codex_weapons_masterwork }),
        armor: await smock.fake('contracts/codex/codex-items-armor-masterwork.sol:codex', { address: devAddresses.codex_armor_masterwork }),
        tools: await smock.fake('contracts/codex/codex-items-tools-masterwork.sol:codex', { address: devAddresses.codex_tools_masterwork })
      }
    }

    this.core = {
      rarity: await fakeRarity()
    }

    this.masterwork = {
      projects: await smock.fake<RarityMasterworkProjects>('contracts/core/rarity_crafting_masterwork_projects.sol:rarity_masterwork_projects'),
      items: await(await smock.mock<RarityMasterworkItems__factory>('contracts/core/rarity_crafting_masterwork_items.sol:rarity_masterwork_items', {
        libraries: {
          Crafting: (await (await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address,
          masterwork_uri: (await(await smock.mock<MasterworkUri__factory>('contracts/core/rarity_crafting_masterwork_uri.sol:masterwork_uri')).deploy()).address,
          Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
        }
      })).deploy()
    }

    await this.masterwork.items.set_project_mint(this.masterwork.projects.address)

    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns({...weapons('longsword', true), id: weaponType.longsword})
  })

  it('claims complete projects', async function() {
    const crafter = fakeSummoner(this.core.rarity, this.signer)

    const projectToken = randomId()
    this.masterwork.projects.ownerOf
    .whenCalledWith(projectToken)
    .returns(this.signer.address)
    this.masterwork.projects.projects
    .whenCalledWith(projectToken)
    .returns([true, baseType.weapon, weaponType.longsword, 0, crafter, 0, 0, 0])

    const token = await this.masterwork.items.next_token()
    await expect(this.masterwork.items.claim(projectToken))
    .to.emit(this.masterwork.items, 'Transfer')
    .withArgs(ethers.constants.AddressZero, this.signer.address, token)
    .to.emit(this.masterwork.items, 'Crafted')
    .withArgs(this.signer.address, token, crafter, baseType.weapon, weaponType.longsword)

    const item = await this.masterwork.items.items(token)
    expect(item.base_type).to.eq(baseType.weapon)
    expect(item.item_type).to.eq(weaponType.longsword)
    expect(item.crafted).to.be.gt(0)
    expect(item.crafter).to.eq(crafter)
  })

  it('can\'t claim projects more than once', async function() {
    const crafter = fakeSummoner(this.core.rarity, this.signer)

    const projectToken = randomId()
    this.masterwork.projects.ownerOf
    .whenCalledWith(projectToken)
    .returns(this.signer.address)
    this.masterwork.projects.projects
    .whenCalledWith(projectToken)
    .returns([true, baseType.weapon, weaponType.longsword, 0, crafter, 0, 0, 0])

    await this.masterwork.items.claim(projectToken)
    await expect(this.masterwork.items.claim(projectToken))
    .to.be.revertedWith('claimed')
  })

  it('rejects incomplete projects', async function() {
    const crafter = fakeSummoner(this.core.rarity, this.signer)

    const projectToken = randomId()
    this.masterwork.projects.ownerOf
    .whenCalledWith(projectToken)
    .returns(this.signer.address)
    this.masterwork.projects.projects
    .whenCalledWith(projectToken)
    .returns([false, baseType.weapon, weaponType.longsword, 0, crafter, 0, 0, 0])

    await expect(this.masterwork.items.claim(projectToken))
    .to.be.revertedWith('!complete')
  })

  it('sets project mint only once', async function() {
    await expect(this.masterwork.items.set_project_mint(this.masterwork.projects.address))
    .to.be.revertedWith('already set')
  })

  it('makes valid token uris', async function() {
    const token = randomId()
    await this.masterwork.items.setVariable('items', {
      [token]: {
        base_type: baseType.weapon,
        item_type: weaponType.longsword,
        crafter: 0,
        crafted: 0,
      }
    })
    const tokenUri = await this.masterwork.items.tokenURI(token)
    const tokenJson = JSON.parse(Buffer.from(tokenUri.split(',')[1], "base64").toString());
    const tokenSvg = Buffer.from(tokenJson.image.split(',')[1], "base64").toString();
    // console.log('tokenJson.image', tokenJson.image)
    expect(isSvg(tokenSvg)).to.be.true;
  })
})