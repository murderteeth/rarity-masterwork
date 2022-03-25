import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { equipmentType, randomId } from '../util'
import { fakeAttributes, fakeCommonCrafting, fakeFeats, fakeLeatherArmor, fakeLongsword, fakeRandom, fakeRarity, fakeSkills } from '../util/fakes'
import { Armor__factory, Feats__factory, Random__factory, Rarity__factory, SkillCheck__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { skills } from '../util/skills'
import { feats } from '../util/feats'
import { Crafting__factory } from '../../typechain/library/factories/Crafting__factory'

chai.use(smock.matchers)

describe('Core: Adventure (II)', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]

    this.codex = {
      random: await fakeRandom()
    }

    this.core = {
      rarity: await fakeRarity(),
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      feats: await fakeFeats()
    }

    this.crafting = {
      common: await fakeCommonCrafting()
    }

    this.adventure = await(await smock.mock<RarityAdventure2__factory>('contracts/core/rarity_adventure-2.sol:rarity_adventure_2', {
      libraries: {
        Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
        SkillCheck: (await(await smock.mock<SkillCheck__factory>('contracts/library/SkillCheck.sol:SkillCheck', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Armor__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
            Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address
          }
        })).deploy()).address,
        Crafting: (await(await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address
      }
    })).deploy()

    this.summon = () => {
      const summoner = randomId()
      this.core.rarity.ownerOf
      .whenCalledWith(summoner)
      .returns(this.signer.address)
      return summoner
    }
  })

  it('starts new adventures', async function () {
    const summoner = this.summon()
    const token = await this.adventure.next_token()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    expect((await this.adventure.adventures(token))['started']).to.be.gt(0)
    expect(await this.adventure.active_adventures(summoner)).to.eq(token)
    expect(this.core.rarity['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.signer.address,
      this.adventure.address,
      summoner
    )
  })

  it('can\'t start more than one active adventure per summoner', async function () {
    const summoner = this.summon()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    await expect(this.adventure.start(summoner)).to.be.revertedWith('active_adventures[summoner] != 0')
  })

  describe('Token AUTH', async function() {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      this.adventure.start(this.summoner)
    })

    it('authorizes the owner of an adventure', async function () {
      expect(await this.adventure.isApprovedOrOwnerOfAdventure(this.token)).to.be.true
    })
  
    it('authorizes address approved for an adventure', async function () {
      const approvedSigner = this.signers[1]
      const signersConnection = await this.adventure.connect(approvedSigner)
      expect(await signersConnection.isApprovedOrOwnerOfAdventure(this.token)).to.be.false
      await this.adventure.approve(approvedSigner.address, this.token)
      expect(await signersConnection.isApprovedOrOwnerOfAdventure(this.token)).to.be.true
    })
  
    it('authorizes address approved for all of the owner\'s adventures', async function () {
      const approvedSigner = this.signers[1]
      const signersConnection = await this.adventure.connect(approvedSigner)
      expect(await signersConnection.isApprovedOrOwnerOfAdventure(this.token)).to.be.false
      await this.adventure.setApprovalForAll(approvedSigner.address, true)
      expect(await signersConnection.isApprovedOrOwnerOfAdventure(this.token)).to.be.true
    })
  })

  describe('Farmer\'s bluff', async function () {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      this.adventure.start(this.summoner)
    })

    it('fails to sense the farmer\'s motives', async function () {
      await expect(this.adventure.sense_farmers_motive(this.token))
      .to.emit(this.adventure, 'SenseFarmersMotive')
      .withArgs(this.token, 1, 0)
  
      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.farmers_bluff_challenged).to.be.true
      expect(adventure.farmers_key).to.be.false
    })
  
    it('senses the farmer\'s motives', async function () {
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 0, 10, 0])
  
      const skillRanks = Array(36).fill(0)
      skillRanks[skills.sense_motive] = 1
      this.core.skills.get_skills
      .whenCalledWith(this.summoner)
      .returns(skillRanks)
  
      const featFlags = Array(100).fill(false)
      featFlags[feats.negotiator] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)
  
      this.codex.random.dn.returns(17)
  
      await expect(this.adventure.sense_farmers_motive(this.token))
      .to.emit(this.adventure, 'SenseFarmersMotive')
      .withArgs(this.token, 17, 20)
  
      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.farmers_bluff_challenged).to.be.true
      expect(adventure.farmers_key).to.be.true
    })
  
    it('can\'t sense motive more than once per adventure', async function (){
      await expect(this.adventure.sense_farmers_motive(this.token)).to.not.be.reverted
      await expect(this.adventure.sense_farmers_motive(this.token)).to.be.revertedWith('farmers_bluff_challenged == true')
    })
  
    it.skip('can\'t sense motive if combat has begun', async function () {
      // TODO
    })
  })

  describe('Eqipment', async function() {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      this.adventure.start(this.summoner)
    })

    it('equips summoners with weapons and armor', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(
        this.token, equipmentType.weapon, this.crafting.common.address, longsword
      )).to.not.be.reverted
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        longsword
      )

      const leatherArmor = fakeLeatherArmor(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(
        this.token, equipmentType.armor, this.crafting.common.address, leatherArmor
      )).to.not.be.reverted
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        leatherArmor
      )

      let slot = await this.adventure.equipment_slots(this.token, equipmentType.weapon)
      expect(slot.item_contract).to.eq(this.crafting.common.address)
      expect(slot.item).to.eq(longsword)

      slot = await this.adventure.equipment_slots(this.token, equipmentType.armor)
      expect(slot.item_contract).to.eq(this.crafting.common.address)
      expect(slot.item).to.eq(leatherArmor)
    })

    it('updates equipment slots', async function () {
      const longsword1 = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, this.crafting.common.address, longsword1)
      const longsword2 = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, this.crafting.common.address, longsword2)
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.adventure.address,
        this.signer.address,
        longsword1
      )
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        longsword2
      )
    })

    it('can\'t equip items in the wrong slot', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await expect(
        this.adventure.equip(this.token, equipmentType.armor, this.crafting.common.address, longsword
      )).to.be.revertedWith('!armor')

      const leatherArmor = fakeLeatherArmor(this.crafting.common, this.summoner, this.signer)
      await expect(
        this.adventure.equip(this.token, equipmentType.weapon, this.crafting.common.address, leatherArmor
      )).to.be.revertedWith('!weapon')
    })

    it('can\'t equip more than one summoner with the same item', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, this.crafting.common.address, longsword)

      const summoner2 = this.summon()
      const token2 = await this.adventure.next_token()
      await this.adventure.start(summoner2)
      await expect(
        this.adventure.equip(token2, equipmentType.weapon, this.crafting.common.address, longsword
      )).to.be.revertedWith('!item available')
    })

    it.skip('can\'t equip items that aren\'t common or masterwork', async function () {
  
    })

    it.skip('can\'t equip if combat has begun', async function () {
  
    })
  })

  it.skip('enters the barn', async function () {

  })

  it.skip('can\'t enter the barn more than once', async function () {

  })

  it.skip('spawns a kobold party leveled to summoners level 3-7', async function () {

  })

  it.skip('catchs the kobolds flat-footed with the farmer\'s key', async function () {

  })

  it.skip('defeats the kobolds', async function () {

  })

  it.skip('flees from the kobolds', async function () {

  })

  it.skip('waits at least one day before starting a new adventure', async function () {

  })
})