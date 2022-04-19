import chai, { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { equipmentType, randomId } from '../util'
import { fakeAttributes, fakeCommonCraftingWrapper, fakeCraft, fakeFeats, fakeFullPlateArmor, fakeGreatsword, fakeHeavyCrossbow, fakeHeavyWoodShield, fakeLeatherArmor, fakeLongsword, fakeMasterwork, fakeRandom, fakeRarity, fakeSkills, fakeSummoner } from '../util/fakes'
import { Attributes__factory, Feats__factory, Proficiency__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { skills } from '../util/skills'
import { feats } from '../util/feats'
import { Crafting__factory } from '../../typechain/library/factories/Crafting__factory'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { classes } from '../util/classes'
import { baseType, toolType, weaponType } from '../util/crafting'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { BigNumber } from 'ethers'

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
      common: await fakeCommonCraftingWrapper(),
      masterwork: await fakeMasterwork()
    }

    this.adventure = await mockAdventure()
    await this.adventure.set_item_whitelist(
      this.crafting.common.address, 
      this.crafting.masterwork.address
    )

    this.crafting.common.get_weapon
    .whenCalledWith(weaponType.greatsword)
    .returns([weaponType.greatsword, 2, 4, 3, 8, 12, 2, -1, 0, ethers.utils.parseEther('50'), "Greatsword", ""])

    this.crafting.common.get_weapon
    .whenCalledWith(weaponType.longsword)
    .returns([weaponType.longsword, 2, 3, 3, 4, 8, 2, -1, 0, ethers.utils.parseEther('15'), "Longsword", ""])

    this.crafting.common.get_weapon
    .whenCalledWith(weaponType.heavyCrossbow)
    .returns([weaponType.heavyCrossbow, 1, 5, 2, 8, 10, 2, -1, 120, ethers.utils.parseEther('50'), "Heavy Crossbow", ""])
  })

  async function mockAdventure() {
    return await(await smock.mock<RarityAdventure2__factory>('contracts/core/rarity_adventure-2.sol:rarity_adventure_2', {
      libraries: {
        Rarity: (await(await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
        Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
        Crafting: (await(await smock.mock<Crafting__factory>('contracts/library/Crafting.sol:Crafting')).deploy()).address,
        Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
            Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
            CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
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
  }

  it('can\'t set a item whitelist address to zero', async function () {
    const adventure = await mockAdventure()
    await expect(adventure.set_item_whitelist(ethers.constants.AddressZero, this.crafting.masterwork.address))
    .to.be.revertedWith('common == address(0)')
    await expect(adventure.set_item_whitelist(this.crafting.common.address, ethers.constants.AddressZero))
    .to.be.revertedWith('masterwork == address(0)')
  })

  it('sets the item whitelist only once', async function () {
    const adventure = await mockAdventure()
    await adventure.set_item_whitelist(this.crafting.common.address, this.crafting.masterwork.address)
    expect(await adventure.ITEM_WHITELIST(0)).to.eq(this.crafting.common.address)
    expect(await adventure.ITEM_WHITELIST(1)).to.eq(this.crafting.masterwork.address)
    await expect(adventure.set_item_whitelist(this.crafting.common.address, this.crafting.masterwork.address))
    .to.be.revertedWith('whitelist already set')
  })

  it('starts new adventures', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    expect((await this.adventure.adventures(token))['started']).to.be.gt(0)
    expect(await this.adventure.latest_adventures(summoner)).to.eq(token)
    expect(this.core.rarity['safeTransferFrom(address,address,uint256)'])
    .to.have.been.calledWith(
      this.signer.address,
      this.adventure.address,
      summoner
    )
    expect(this.core.rarity.approve)
    .to.have.been.calledWith(
      this.signer.address,
      summoner
    )
  })

  it('can\'t start more than one active adventure per summoner', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    await expect(this.adventure.start(summoner)).to.be.revertedWith('!latest_adventure.ended')
  })

  it('is outside the dungeon', async function() {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()    
    await this.adventure.start(summoner)
    expect(await this.adventure.is_outside_dungeon(token)).to.be.true
    await this.adventure.enter_dungeon(token)
    expect(await this.adventure.is_outside_dungeon(token)).to.be.false
    await this.adventure.flee(token)
    expect(await this.adventure.is_outside_dungeon(token)).to.be.false
    await this.adventure.end(token)
    expect(await this.adventure.is_outside_dungeon(token)).to.be.false
  })

  it('is en combat', async function() {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    expect(await this.adventure.is_en_combat(token)).to.be.false
    await this.adventure.enter_dungeon(token)
    expect(await this.adventure.is_en_combat(token)).to.be.true
    await this.adventure.flee(token)
    expect(await this.adventure.is_en_combat(token)).to.be.false
    await this.adventure.end(token)
    expect(await this.adventure.is_en_combat(token)).to.be.false
  })

  it('is combat over', async function() {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    expect(await this.adventure.is_combat_over(token)).to.be.false
    await this.adventure.enter_dungeon(token)
    expect(await this.adventure.is_combat_over(token)).to.be.false
    await this.adventure.flee(token)
    expect(await this.adventure.is_combat_over(token)).to.be.true
    await this.adventure.end(token)
    expect(await this.adventure.is_combat_over(token)).to.be.false
  })

  it('is ended', async function() {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    expect(await this.adventure.is_ended(token)).to.be.false
    await this.adventure.enter_dungeon(token)
    expect(await this.adventure.is_ended(token)).to.be.false
    await this.adventure.flee(token)
    expect(await this.adventure.is_ended(token)).to.be.false
    await this.adventure.end(token)
    expect(await this.adventure.is_ended(token)).to.be.true
  })

  it('is victory', async function() {
    const token = randomId()
    await this.adventure.setVariable('adventures', { [token] : {
      monster_count: 1,
      monsters_defeated: 1
    }})
    expect(await this.adventure.is_victory(token)).to.be.true

    await this.adventure.setVariable('adventures', { [token] : {
      monster_count: 1,
      monsters_defeated: 0
    }})
    expect(await this.adventure.is_victory(token)).to.be.false
  })

  describe('Token AUTH', async function() {
    beforeEach(async function(){
      this.summoner = fakeSummoner(this.core.rarity, this.signer)
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

  describe('Equipment', async function() {
    beforeEach(async function(){
      this.summoner = fakeSummoner(this.core.rarity, this.signer)
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
    })

    it('equips summoners with weapons and armor', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        longsword
      )
      expect(this.crafting.common.approve)
      .to.have.been.calledWith(
        this.signer.address,
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
      expect(this.crafting.common.approve)
      .to.have.been.calledWith(
        this.signer.address,
        leatherArmor
      )

      const heavyWoodShield = fakeHeavyWoodShield(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(
        this.token, equipmentType.shield, heavyWoodShield, this.crafting.common.address
      )).to.not.be.reverted
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        heavyWoodShield
      )
      expect(this.crafting.common.approve)
      .to.have.been.calledWith(
        this.signer.address,
        heavyWoodShield
      )

      let slot = await this.adventure.equipment_slots(this.token, equipmentType.weapon)
      expect(slot.item_contract).to.eq(this.crafting.common.address)
      expect(slot.item).to.eq(longsword)

      slot = await this.adventure.equipment_slots(this.token, equipmentType.armor)
      expect(slot.item_contract).to.eq(this.crafting.common.address)
      expect(slot.item).to.eq(leatherArmor)

      slot = await this.adventure.equipment_slots(this.token, equipmentType.shield)
      expect(slot.item_contract).to.eq(this.crafting.common.address)
      expect(slot.item).to.eq(heavyWoodShield)
    })

    it('updates equipment slots', async function () {
      const longsword1 = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword1, this.crafting.common.address)
      const longsword2 = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword2, this.crafting.common.address)
      expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
        this.signer.address,
        this.adventure.address,
        longsword1
      )
      expect(this.crafting.common.approve)
      .to.have.been.calledWith(
        this.signer.address,
        longsword1
      )
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
      await expect(this.adventure.equip(
        this.token, equipmentType.shield, 0, ethers.constants.AddressZero
      )).to.not.be.reverted
    })

    it('rejects items from non-whitelist contracts', async function () {
      const rando_craft = await smock.fake('contracts/core/rarity_crafting_common_wrapper.sol:rarity_crafting_wrapper')
      const greatsword = fakeGreatsword(rando_craft, this.summoner, this.signer)

      rando_craft.get_weapon
      .whenCalledWith(weaponType.greatsword)
      .returns([weaponType.greatsword, 2, 4, 3, 8, 12, 2, -1, 0, ethers.utils.parseEther('50'), "Greatsword", ""])

      await expect(this.adventure.equip(this.token, equipmentType.weapon, greatsword, rando_craft.address))
      .to.be.revertedWith('!whitelist')
    })

    it('can\'t equip a two-handed weapon after a shield', async function () {
      const heavyWoodShield = fakeHeavyWoodShield(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.shield, heavyWoodShield, this.crafting.common.address)
      const greatsword = fakeGreatsword(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(this.token, equipmentType.weapon, greatsword, this.crafting.common.address))
      .to.be.revertedWith('shield equipped')
    })

    it('can\'t equip a shield after a two-handed weapon', async function () {
      const greatsword = fakeGreatsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, greatsword, this.crafting.common.address)
      const heavyWoodShield = fakeHeavyWoodShield(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(this.token, equipmentType.shield, heavyWoodShield, this.crafting.common.address))
      .to.be.revertedWith('two-handed weapon equipped')
    })

    it('can\'t equip ranged weapons', async function () {
      const heavyCrossbow = fakeHeavyCrossbow(this.crafting.common, this.summoner, this.signer)
      await expect(this.adventure.equip(this.token, equipmentType.weapon, heavyCrossbow, this.crafting.common.address))
      .to.be.revertedWith('ranged weapon')
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

      await expect(
        this.adventure.equip(this.token, equipmentType.shield, leatherArmor, this.crafting.common.address
      )).to.be.revertedWith('!shield')
    })

    it('can\'t equip more than one summoner with the same item', async function () {
      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)

      const summoner2 = fakeSummoner(this.core.rarity, this.signer)
      const token2 = await this.adventure.next_token()
      await this.adventure.start(summoner2)
      await expect(
        this.adventure.equip(token2, equipmentType.weapon, longsword, this.crafting.common.address
      )).to.be.revertedWith('!item available')
    })
  })

  describe('Dungeon', async function() {
    beforeEach(async function(){
      this.summoner = fakeSummoner(this.core.rarity, this.signer)
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
    })

    it('enters dungeon', async function () {
      await this.adventure.enter_dungeon(this.token)
      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.dungeon_entered).to.be.true
      expect(adventure.combat_round).to.eq(1)
      expect(adventure.monster_count).to.be.gt(0)
    })

    it('rolls monsters', async function() {
      this.codex.random.dn
      .whenCalledWith(BigNumber.from('12586470658909511785'), this.token, 100)
      .returns(50)

      expect((await this.adventure.roll_monsters(this.token, 1)).monster_count).to.eq(1)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('12586470658909511785'), this.token, 100)
      .returns(51)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('15608573760256557610'), this.token, 2)
      .returns(2)

      expect((await this.adventure.roll_monsters(this.token, 1)).monster_count).to.eq(2)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('15608573760256557610'), this.token, 3)
      .returns(3)

      expect((await this.adventure.roll_monsters(this.token, 2)).monster_count).to.eq(2)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('15608573760256557610'), this.token, 4)
      .returns(4)

      expect((await this.adventure.roll_monsters(this.token, 3)).monster_count).to.eq(2)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('1593506169583491991'), this.token, 100)
      .returns(50)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('15608573760256557610'), this.token, 5)
      .returns(5)

      expect((await this.adventure.roll_monsters(this.token, 4)).monster_count).to.eq(2)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('1593506169583491991'), this.token, 100)
      .returns(51)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('9249786475706550225'), this.token, 5)
      .returns(5)

      expect((await this.adventure.roll_monsters(this.token, 4)).monster_count).to.eq(3)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('9249786475706550225'), this.token, 9)
      .returns(9)
      expect((await this.adventure.roll_monsters(this.token, 20)).monster_count).to.eq(3)

      const monsters = (await this.adventure.roll_monsters(this.token, 20)).monsters
      monsters.forEach((monster: any) => expect(monster).to.be.above(0))
    })

    it('orders combatants by initiative', async function () {
      const featFlags = Array(100).fill(false)
      featFlags[feats.improved_initiative] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)

      await this.adventure.enter_dungeon(this.token)
      expect((await this.adventure.turn_orders(this.token, 0)).origin).to.eq(this.core.rarity.address)
      expect((await this.adventure.turn_orders(this.token, 1)).origin).to.eq(this.adventure.address)
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
      const tx = await(await this.adventure.enter_dungeon(this.token)).wait()
      const attack = tx.events[1];
      expect(attack.args.hit).to.be.false;
    })

    it('can crit on strong summoners', async function () {
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
      const tx = await(await this.adventure.enter_dungeon(this.token)).wait()
      const attack = tx.events[1];
      expect(attack.args.hit).to.be.true;
      expect(attack.args.critical_confirmation).to.be.gt(0);
      expect(attack.args.damage).to.be.gt(0);
    })

    it('experienced fighters get multiple attacks per round', async function () {
      this.codex.random.dn.returns(15)

      this.core.rarity.class
      .whenCalledWith(this.summoner)
      .returns(classes.fighter)

      this.core.rarity.level
      .whenCalledWith(this.summoner)
      .returns(6)

      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([24, 24, 24, 0, 0, 0])

      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const fullPlate = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      await this.adventure.equip(this.token, equipmentType.armor, fullPlate, this.crafting.common.address)
      await this.adventure.enter_dungeon(this.token)
      let target = await this.adventure.next_able_monster(this.token)
      await this.adventure.attack(this.token, target)
      expect((await this.adventure.adventures(this.token)).combat_round).to.eq(1)
    })

    it('defeats the monsters', async function () {
      this.codex.random.dn.returns(2)

      this.core.rarity.class
      .whenCalledWith(this.summoner)
      .returns(classes.fighter)

      this.core.rarity.level
      .whenCalledWith(this.summoner)
      .returns(20)

      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([64, 64, 64, 0, 0, 0])

      const longsword = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const fullPlate = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      await this.adventure.equip(this.token, equipmentType.weapon, longsword, this.crafting.common.address)
      await this.adventure.equip(this.token, equipmentType.armor, fullPlate, this.crafting.common.address)
      await this.adventure.enter_dungeon(this.token)

      while(!(await this.adventure.adventures(this.token)).combat_ended) {
        const target = await this.adventure.next_able_monster(this.token)
        await this.adventure.attack(this.token, target)
      }

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.monster_count).to.eq(adventure.monsters_defeated)
      const summoners_turn = await this.adventure.summoners_turns(this.token)
      const summoner_combatant = await this.adventure.turn_orders(this.token, summoners_turn)
      expect(summoner_combatant.hit_points).to.be.gt(-1)
    })

    it('rejects attacks on invalid targets', async function () {
      this.codex.random.dn.returns(1)
      await this.adventure.enter_dungeon(this.token)
      await expect(this.adventure.attack(this.token, 100)).to.be.revertedWith('target out of bounds')
    })

    it('only attacks monsters', async function () {
      this.codex.random.dn.returns(1)
      await this.adventure.enter_dungeon(this.token)
      const summoners_turn = await this.adventure.summoners_turns(this.token)
      await expect(this.adventure.attack(this.token, summoners_turn)).to.be.revertedWith('monster.origin != address(this)')
    })

    it('flees combat', async function () {
      this.codex.random.dn.returns(1)
      await this.adventure.enter_dungeon(this.token)
      await this.adventure.flee(this.token)
      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.combat_ended).to.be.true
      expect(adventure.combat_round).to.eq(1)
      expect(adventure.monster_count).to.be.gt(adventure.monsters_defeated)
      const summoners_turn = await this.adventure.summoners_turns(this.token)
      const summoner_combatant = await this.adventure.turn_orders(this.token, summoners_turn)
      expect(summoner_combatant.hit_points).to.be.gt(-1)
    })
  })

  describe('Loot', async function () {
    beforeEach(async function(){
      this.summoner = fakeSummoner(this.core.rarity, this.signer)
      this.token = await this.adventure.next_token()
      await this.adventure.start(this.summoner)
      await this.adventure.setVariable('adventures', { [this.token] : {
        monster_count: 1,
        monsters_defeated: 1
      }})
    })

    it('fails search check', async function () {
      await expect(this.adventure.search(this.token))
      .to.emit(this.adventure, 'SearchCheck')
      .withArgs(this.signer.address, this.token, 1, 0)

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.search_check_rolled).to.be.true
      expect(adventure.search_check_succeeded).to.be.false
    })

    it('succeeds search check', async function () {
      this.core.attributes.ability_scores
      .whenCalledWith(this.summoner)
      .returns([0, 0, 0, 10, 0, 0])

      const skillRanks = Array(36).fill(0)
      skillRanks[skills.search] = 1
      this.core.skills.get_skills
      .whenCalledWith(this.summoner)
      .returns(skillRanks)

      const featFlags = Array(100).fill(false)
      featFlags[feats.investigator] = true
      this.core.feats.get_feats
      .whenCalledWith(this.summoner)
      .returns(featFlags)

      this.codex.random.dn.returns(17)

      await expect(this.adventure.search(this.token))
      .to.emit(this.adventure, 'SearchCheck')
      .withArgs(this.signer.address, this.token, 17, 20)

      const adventure = await this.adventure.adventures(this.token)
      expect(adventure.search_check_rolled).to.be.true
      expect(adventure.search_check_succeeded).to.be.true
    })

    it('can\'t search more than once', async function (){
      await expect(this.adventure.search(this.token)).to.not.be.reverted
      await expect(this.adventure.search(this.token)).to.be.revertedWith('search_check_rolled')
    })
  })

  it('ends the adventure', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)

    const longsword = fakeLongsword(this.crafting.common, summoner, this.signer)
    const fullPlate = fakeFullPlateArmor(this.crafting.common, summoner, this.signer)
    const heavyWoodShield = fakeHeavyWoodShield(this.crafting.common, summoner, this.signer)
    await this.adventure.equip(token, equipmentType.weapon, longsword, this.crafting.common.address)
    await this.adventure.equip(token, equipmentType.armor, fullPlate, this.crafting.common.address)
    await this.adventure.equip(token, equipmentType.shield, heavyWoodShield, this.crafting.common.address)

    await this.adventure.end(token)

    expect(this.core.rarity['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.adventure.address,
      this.signer.address,
      summoner
    )
    expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.adventure.address,
      this.signer.address,
      longsword
    )
    expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.adventure.address,
      this.signer.address,
      fullPlate
    )
    expect(this.crafting.common['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.adventure.address,
      this.signer.address,
      heavyWoodShield
    )

    const adventure = await this.adventure.adventures(token)
    expect(adventure.ended).to.be.gt(0)
  })

  it('only ends the adventure once', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    await this.adventure.end(token)
    await expect(this.adventure.end(token)).to.be.revertedWith('ended')
  })

  it('computes time to next adventure', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    await this.adventure.start(summoner)
    expect(await this.adventure.time_to_next_adventure(summoner)).to.eq(1 * 24 * 60 * 60)
    await network.provider.send("evm_increaseTime", [1 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");
    expect(await this.adventure.time_to_next_adventure(summoner)).to.eq(0)
    await network.provider.send("evm_increaseTime", [100 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");
    expect(await this.adventure.time_to_next_adventure(summoner)).to.eq(0)
  })

  it('waits at least one day before starting a new adventure', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    await this.adventure.end(token)
    await expect(this.adventure.start(summoner)).to.be.revertedWith('!1day')
    await network.provider.send("evm_increaseTime", [1 * 24 * 60 * 60]);
    await network.provider.send("evm_mine");
    await expect(this.adventure.start(summoner)).to.not.be.reverted
  })
})