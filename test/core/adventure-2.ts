import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { equipmentType, randomId } from '../util'
import { fakeAttributes, fakeCommonCrafting, fakeFeats, fakeFullPlateArmor, fakeLeatherArmor, fakeLongsword, fakeRandom, fakeRarity, fakeSkills } from '../util/fakes'
import { Attributes__factory, Feats__factory, Proficiency__factory, Random__factory, Rarity__factory, Roll__factory, SkillCheck__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { skills } from '../util/skills'
import { feats } from '../util/feats'
import { Crafting__factory } from '../../typechain/library/factories/Crafting__factory'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { classes } from '../util/classes'

chai.use(smock.matchers)

describe('Core: Adventure II', function () {
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
        Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
        Crafting: (await(await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address,
        Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
            Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address
          }
        })).deploy()).address,
        Summoner: (await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner', {
          libraries: {
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Proficiency: (await (await smock.mock<Proficiency__factory>('contracts/library/Proficiency.sol:Proficiency', {
              libraries: {
                Feats: (await (await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
                Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
              }
            })).deploy()).address,
            Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
          }
        })).deploy()).address,
        Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address
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
      await this.adventure.start(this.summoner)
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

  describe('Skill check', async function () {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
    })

    it('fails skill check', async function () {
      await expect(this.adventure.sense_motive(this.token))
      .to.emit(this.adventure, 'SenseMotive')
      .withArgs(this.token, 1, 0)

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.skill_check_rolled).to.be.true
      expect(adventure.skill_check_succeeded).to.be.false
    })
  
    it('succeeds skill check', async function () {
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

      await expect(this.adventure.sense_motive(this.token))
      .to.emit(this.adventure, 'SenseMotive')
      .withArgs(this.token, 17, 20)

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.skill_check_rolled).to.be.true
      expect(adventure.skill_check_succeeded).to.be.true
    })

    it('can\'t skill check more than once per adventure', async function (){
      await expect(this.adventure.sense_motive(this.token)).to.not.be.reverted
      await expect(this.adventure.sense_motive(this.token)).to.be.revertedWith('skill_check_rolled')
    })

    it('can\'t skill check if combat has started', async function () {
      await this.adventure.start_combat(this.token)
      await expect(this.adventure.sense_motive(this.token)).to.be.revertedWith('combat_started')
    })
  })

  describe('Equipment', async function() {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
    })

    it('equips summoners with weapons and armor', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(
        this.token, equipmentType.weapon, longsword, this.crafting.common.address
      )).to.not.be.reverted
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        longsword
      )

      const leatherArmor = fakeLeatherArmor(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(
        this.token, equipmentType.armor, leatherArmor, this.crafting.common.address
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
      await this.adventure.equip(this.token, equipmentType.weapon, longsword1, this.crafting.common.address)
      const longsword2 = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword2, this.crafting.common.address)
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

    it('equips unarmed summoners', async function () {
      await expect(this.adventure.equip(
        this.token, equipmentType.weapon, 0, ethers.constants.AddressZero
      )).to.not.be.reverted
      await expect(this.adventure.equip(
        this.token, equipmentType.armor, 0, ethers.constants.AddressZero
      )).to.not.be.reverted
    })

    it('can\'t equip items in the wrong slot', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await expect(
        this.adventure.equip(this.token, equipmentType.armor, longsword, this.crafting.common.address
      )).to.be.revertedWith('!armor')

      const leatherArmor = fakeLeatherArmor(this.crafting.common, this.summoner, this.signer)
      await expect(
        this.adventure.equip(this.token, equipmentType.weapon, leatherArmor, this.crafting.common.address
      )).to.be.revertedWith('!weapon')
    })

    it('can\'t equip more than one summoner with the same item', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)

      const summoner2 = this.summon()
      const token2 = await this.adventure.next_token()
      await this.adventure.start(summoner2)
      await expect(
        this.adventure.equip(token2, equipmentType.weapon, longsword, this.crafting.common.address
      )).to.be.revertedWith('!item available')
    })

    it.skip('can\'t equip items that aren\'t common or masterwork', async function () {

    })

    it('can\'t equip if combat has begun', async function () {
      await this.adventure.start_combat(this.token)
      await expect(this.adventure.equip(
        this.token, equipmentType.weapon, 0, ethers.constants.AddressZero
      )).to.be.revertedWith('combat_started')
    })
  })

  describe('Dungeon', async function() {
    beforeEach(async function(){
      this.summoner = this.summon()
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
    })

    it('starts combat', async function () {
      await this.adventure.start_combat(this.token)
      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.combat_started).to.be.true
      expect(adventure.combat_round).to.eq(1)
      expect(adventure.monster_count).to.eq(2)
    })

    it('can only start combat once', async function () {
      await expect(this.adventure.start_combat(this.token)).to.not.be.reverted
      await expect(this.adventure.start_combat(this.token)).to.be.revertedWith('combat_started')
    })

    it('orders combatants by initiative', async function () {
      const featFlags = Array(100).fill(false)
      featFlags[feats.improved_initiative] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)

      await this.adventure.start_combat(this.token)
      expect((await this.adventure.turn_orders(this.token, 0)).summoner).to.be.true
      expect((await this.adventure.turn_orders(this.token, 1)).summoner).to.be.false
    })

    it('can attack and miss weak summoners', async function () {
      this.codex.random.dn.returns(1)

      this.core.rarity.class
      .whenCalledWith(this.summoner)
      .returns(classes.wizard)

      this.core.rarity.level
      .whenCalledWith(this.summoner)
      .returns(1)

      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 9, 0, 0, 0, 0])

      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const fullPlate = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      await this.adventure.equip(this.token, equipmentType.armor, fullPlate, this.crafting.common.address)
      const tx = await(await this.adventure.start_combat(this.token)).wait()
      const attack = tx.events[1];
      expect(attack.args.hit).to.be.false;
    })

    it('can crit on stronge summoners', async function () {
      this.codex.random.dn.returns(20)

      this.core.rarity.class
      .whenCalledWith(this.summoner)
      .returns(classes.barbarian)

      this.core.rarity.level
      .whenCalledWith(this.summoner)
      .returns(6)

      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([18, 0, 0, 0, 0, 0])

      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const fullPlate = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      await this.adventure.equip(this.token, equipmentType.armor, fullPlate, this.crafting.common.address)
      const tx = await(await this.adventure.start_combat(this.token)).wait()
      const attack = tx.events[1];
      expect(attack.args.hit).to.be.true;
      expect(attack.args.critical_confirmation).to.be.gt(0);
      expect(attack.args.damage).to.be.gt(0);
    })

    it('defeats the monsters', async function () {
      this.codex.random.dn.returns(15)

      this.core.rarity.class
      .whenCalledWith(this.summoner)
      .returns(classes.fighter)

      this.core.rarity.level
      .whenCalledWith(this.summoner)
      .returns(5)

      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([18, 12, 14, 0, 0, 0])

      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const fullPlate = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      await this.adventure.equip(this.token, equipmentType.armor, fullPlate, this.crafting.common.address)
      await this.adventure.start_combat(this.token)

      let expectedRound = 0
      while(!(await this.adventure.adventures(this.token)).combat_ended) {
        const target = await this.adventure.next_able_monster(this.token)
        await this.adventure.attack(this.token, target)
        expectedRound++;
      }

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.combat_round).to.eq(expectedRound)
      expect(adventure.monster_count).to.eq(adventure.monsters_defeated)
    })
  })

  it.skip('ends the adventure', async function () {

  })

  it.skip('waits at least one day before starting a new adventure', async function () {

  })
})