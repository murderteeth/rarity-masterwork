import chai, { expect } from 'chai'
import { ethers, network } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import isSvg from 'is-svg'
import { equipmentSlot, randomId } from '../../util'
import { fakeAttributes, fakeCommonCrafting, fakeEquipment, fakeFeats, fakeFullPlateArmor, fakeHeavyWoodShield, fakeLongsword, fakeMasterworkProjects, fakeRandom, fakeRarity, fakeSkills, fakeSummoner } from '../../util/fakes'
import { Attributes__factory, Feats__factory, Monster__factory, Proficiency__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { AdventureUri__factory } from '../../typechain/core'
import { skills } from '../../util/skills'
import { feats } from '../../util/feats'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { classes } from '../../util/classes'
import { CraftingSkills__factory } from '../../typechain/library/factories/CraftingSkills__factory'
import { BigNumber } from 'ethers'
import devAddresses from '../../addresses.dev.json'
import { armorType, weaponType } from '../../util/crafting'
import { armors, weapons } from '../../util/equipment'

chai.use(smock.matchers)

describe('Core: Adventure II', function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    this.signer = this.signers[0]

    this.codex = {
      random: await fakeRandom(),
      common: {
        armor: await smock.fake('contracts/codex/codex-items-armor-2.sol:codex', { address: devAddresses.codex_armor_2 }),
        weapons: await smock.fake('contracts/codex/codex-items-weapons-2.sol:codex', { address: devAddresses.codex_weapons_2 })
      }
    }

    this.core = {
      rarity: await fakeRarity(),
      attributes: await fakeAttributes(),
      skills: await fakeSkills(),
      feats: await fakeFeats()
    }

    this.crafting = {
      common: await fakeCommonCrafting(),
      masterwork: await fakeMasterworkProjects()
    }

    this.codex.common.weapons.item_by_id
    .whenCalledWith(weaponType.greatsword)
    .returns(weapons('greatsword'))

    this.codex.common.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns(weapons('longsword'))

    this.codex.common.armor.item_by_id
    .whenCalledWith(armorType.fullPlate)
    .returns(armors('full plate'))

    this.codex.common.armor.item_by_id
    .whenCalledWith(armorType.heavyWoodShield)
    .returns(armors('shield, heavy wooden'))

    this.equipment = await fakeEquipment()
    this.equipment.codexes
    .whenCalledWith(this.crafting.common.address, 2)
    .returns(this.codex.common.armor.address)

    this.equipment.codexes
    .whenCalledWith(this.crafting.common.address, 3)
    .returns(this.codex.common.weapons.address)

    this.adventure_uri = await mockAdvenutreUri()
    this.adventure = await mockAdventure(this.adventure_uri)
  })

  async function mockAdvenutreUri() {
    return await(await smock.mock<AdventureUri__factory>('contracts/core/rarity_adventure_2_uri.sol:adventure_uri', {
      libraries: {
        Monster: (await(await smock.mock<Monster__factory>('contracts/library/Monster.sol:Monster', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
              libraries: {
                Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
                Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
                Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
                Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
                CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
              }
            })).deploy()).address
          }
        })).deploy()).address
      }
    })).deploy()
  }

  async function mockAdventure(adventure_uri: any) {
    return await(await smock.mock<RarityAdventure2__factory>('contracts/core/rarity_adventure_2.sol:rarity_adventure_2', {
      libraries: {
        adventure_uri: adventure_uri.address,
        Monster: (await(await smock.mock<Monster__factory>('contracts/library/Monster.sol:Monster', {
          libraries: {
            Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
              libraries: {
                Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
                Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
                Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
                Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
                CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
              }
            })).deploy()).address
          }
        })).deploy()).address,
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
        Summoner: (await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner', {
          libraries: {
            Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
            Proficiency: (await (await smock.mock<Proficiency__factory>('contracts/library/Proficiency.sol:Proficiency', {
              libraries: {
                Feats: (await (await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
                Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address
              }
            })).deploy()).address,
            Rarity: (await (await smock.mock<Rarity__factory>('contracts/library/Rarity.sol:Rarity')).deploy()).address,
            Roll: (await(await smock.mock<Roll__factory>('contracts/library/Roll.sol:Roll', {
              libraries: {
                Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address,
                Attributes: (await (await smock.mock<Attributes__factory>('contracts/library/Attributes.sol:Attributes')).deploy()).address,
                Feats: (await(await smock.mock<Feats__factory>('contracts/library/Feats.sol:Feats')).deploy()).address,
                Skills: (await (await smock.mock<Skills__factory>('contracts/library/Skills.sol:Skills')).deploy()).address,
                CraftingSkills: (await(await smock.mock<CraftingSkills__factory>('contracts/library/CraftingSkills.sol:CraftingSkills')).deploy()).address
              }
            })).deploy()).address
          }
        })).deploy()).address,
        Random: (await (await smock.mock<Random__factory>('contracts/library/Random.sol:Random')).deploy()).address
      }
    })).deploy()
  }

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

      expect((await this.adventure.roll_monsters(this.token, 7)).monster_count).to.eq(2)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('1593506169583491991'), this.token, 100)
      .returns(51)

      this.codex.random.dn
      .whenCalledWith(BigNumber.from('9249786475706550225'), this.token, 5)
      .returns(5)

      expect((await this.adventure.roll_monsters(this.token, 7)).monster_count).to.eq(3)

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
      expect((await this.adventure.turn_orders(this.token, 0)).mint).to.eq(this.core.rarity.address)
      expect((await this.adventure.turn_orders(this.token, 1)).mint).to.eq(this.adventure.address)
    })

    it('can attack and miss weak, defensless summoners', async function () {
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

      const weapon = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const armor = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      const shield = fakeHeavyWoodShield(this.crafting.common, this.summoner, this.signer)
  
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.weapon1)
      .returns([this.crafting.common.address, weapon])
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.armor)
      .returns([this.crafting.common.address, armor])
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.shield)
      .returns([this.crafting.common.address, shield])

      const tx = await(await this.adventure.enter_dungeon(this.token)).wait()
      const attack = tx.events[1];
      expect(attack.args.hit).to.be.true;
      expect(attack.args.critical_confirmation).to.be.gt(0);
      expect(attack.args.damage).to.be.gt(0);
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

      const weapon = fakeLongsword(this.crafting.common, this.summoner, this.signer)
      const armor = fakeFullPlateArmor(this.crafting.common, this.summoner, this.signer)
      const shield = fakeHeavyWoodShield(this.crafting.common, this.summoner, this.signer)
  
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.weapon1)
      .returns([this.crafting.common.address, weapon])
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.armor)
      .returns([this.crafting.common.address, armor])
      this.equipment.slots
      .whenCalledWith(this.summoner, equipmentSlot.shield)
      .returns([this.crafting.common.address, shield])

      await this.adventure.enter_dungeon(this.token)

      while(!(await this.adventure.adventures(this.token)).combat_ended) {
        const target = await this.adventure.next_able_monster(this.token)
        await this.adventure.attack(this.token, target)
      }

      const adventure = await this.adventure.end(this.token)
      expect(adventure.monster_count).to.eq(adventure.monsters_defeated)
      const summoners_turn = await this.adventure.summoners_turns(this.token)
      const summoner_combatant = await this.adventure.turn_orders(this.token, summoners_turn)
      expect(summoner_combatant.hit_points).to.be.gt(-1)
    })

    it('only attacks inbounds targets', async function () {
      this.codex.random.dn.returns(1)
      await this.adventure.enter_dungeon(this.token)
      await expect(this.adventure.attack(this.token, 100)).to.be.revertedWith('target out of bounds')
    })

    it('only attacks monsters', async function () {
      this.codex.random.dn.returns(1)
      await this.adventure.enter_dungeon(this.token)
      const summoners_turn = await this.adventure.summoners_turns(this.token)
      await expect(this.adventure.attack(this.token, summoners_turn)).to.be.revertedWith('monster.mint != address(this)')
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
      expect(await this.adventure.was_fled(this.token)).to.be.true
    })
  })

  describe('Loot', async function () {
    beforeEach(async function(){
      this.summoner = fakeSummoner(this.core.rarity, this.signer)
      this.token = await this.adventure.next_token()
      this.codex.random.dn
      .whenCalledWith('12586470658909511785', this.token, 100)
      .returns(1)
      this.codex.random.dn
      .whenCalledWith('1593506169583491991', this.token, 100)
      .returns(1)
      await this.adventure.start(this.summoner)
      await this.adventure.enter_dungeon(this.token)
      await this.adventure.setVariable('adventures', { [this.token] : {
        monster_count: 1,
        monsters_defeated: 1,
        combat_ended: true
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

    it('counts standard loot', async function() {
      expect(await this.adventure.count_loot(this.token)).to.deep.eq(ethers.utils.parseEther('10'))
    })

    it('counts loot with successful search check', async function() {
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
      expect(await this.adventure['count_loot(uint256)'](this.token)).to.deep.eq(ethers.utils.parseEther('11.5'))
    })

    it('counts loot with critical search check', async function() {
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

      this.codex.random.dn.returns(20)
      await expect(this.adventure.search(this.token))
      expect(await this.adventure['count_loot(uint256)'](this.token)).to.deep.eq(ethers.utils.parseEther('12'))
    })
  })

  it('ends the adventure', async function () {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    await this.adventure.end(token)

    expect(this.core.rarity['safeTransferFrom(address,address,uint256)']).to.have.been.calledWith(
      this.adventure.address,
      this.signer.address,
      summoner
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

  it('makes valid token uris', async function() {
    const summoner = fakeSummoner(this.core.rarity, this.signer)
    this.codex.random.dn.returns(2)

    this.core.rarity.class
    .whenCalledWith(summoner)
    .returns(classes.fighter)
    
    this.core.rarity.level
    .whenCalledWith(summoner)
    .returns(20)
    
    this.core.attributes.ability_scores
    .whenCalledWith(summoner)
    .returns([64, 64, 64, 0, 0, 0])

    const token = await this.adventure.next_token()

    this.codex.random.dn
    .whenCalledWith('12586470658909511785', token, 100)
    .returns(51)
    this.codex.random.dn
    .whenCalledWith('15608573760256557610', token, 9)
    .returns(3)

    this.codex.random.dn
    .whenCalledWith('1593506169583491991', token, 100)
    .returns(51)
    this.codex.random.dn
    .whenCalledWith('15241373560133191304', token, 9)
    .returns(7)

    await this.adventure.start(summoner)
    const weapon = fakeLongsword(this.crafting.common, summoner, this.signer)
    const armor = fakeFullPlateArmor(this.crafting.common, summoner, this.signer)
    const shield = fakeHeavyWoodShield(this.crafting.common, summoner, this.signer)

    this.equipment.snapshots
    .whenCalledWith(this.adventure.address, token, summoner, equipmentSlot.weapon1)
    .returns([this.crafting.common.address, weapon])
    this.equipment.snapshots
    .whenCalledWith(this.adventure.address, token, summoner, equipmentSlot.armor)
    .returns([this.crafting.common.address, armor])
    this.equipment.snapshots
    .whenCalledWith(this.adventure.address, token, summoner, equipmentSlot.shield)
    .returns([this.crafting.common.address, shield])

    await this.adventure.enter_dungeon(token)
    
    while(!(await this.adventure.adventures(token)).combat_ended) {
      const target = await this.adventure.next_able_monster(token)
      await this.adventure.attack(token, target)
    }

    await this.adventure.end(token)
    const tokenUri = await this.adventure.tokenURI(token)
    const tokenJson = JSON.parse(Buffer.from(tokenUri.split(',')[1], "base64").toString());
    const tokenSvg = Buffer.from(tokenJson.image.split(',')[1], "base64").toString();
    // console.log('tokenJson.image', tokenJson.image)
    expect(isSvg(tokenSvg)).to.be.true;
  })
})