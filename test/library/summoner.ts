import { expect } from 'chai'
import { smock } from '@defi-wonderland/smock'
import { enumberance, randomId, unpackAttacks } from '../../util'
import { armorType, baseType, weaponType } from '../../util/crafting'
import { fakeAttributes, fakeCommonCrafting, fakeEquipment, fakeFullPlateArmor, fakeHeavyWoodShield, fakeLongsword, fakeMasterworkItems, fakeMasterworkProjects, fakeRarity } from '../../util/fakes'
import { ethers } from 'hardhat'
import { Summoner__factory } from '../../typechain/library/factories/Summoner__factory'
import { Attributes__factory, CraftingSkills__factory, Feats__factory, Proficiency__factory, Random__factory, Rarity__factory, Roll__factory, Skills__factory } from '../../typechain/library'
import { classes } from '../../util/classes'
import devAddresses from '../../addresses.dev.json'
import { armors, weapons } from '../../util/equipment'

describe('Library: Summoner', function () {
  before(async function () {
    this.signer = (await ethers.getSigners())[0]
    this.summoner = randomId()
    this.longsword = randomId()
    this.fullPlate = randomId()
    this.shield = randomId()

    this.rarity = await fakeRarity()
    this.attributes = await fakeAttributes()
    this.commonCrafting = await fakeCommonCrafting()
    this.masterwork = { items: await fakeMasterworkItems() }
    this.equipment = await fakeEquipment()

    this.codex = {
      common: {
        armor: await smock.fake('contracts/codex/codex-items-armor-2.sol:codex', { address: devAddresses.codex_armor_2 }),
        weapons: await smock.fake('contracts/codex/codex-items-weapons-2.sol:codex', { address: devAddresses.codex_weapons_2 })
      },
      masterwork: {
        armor: await smock.fake('contracts/codex/codex-items-armor-masterwork.sol:codex', { address: devAddresses.codex_armor_masterwork }),
        weapons: await smock.fake('contracts/codex/codex-items-weapons-masterwork.sol:codex', { address: devAddresses.codex_weapons_masterwork })
      }
    }

    this.library = {
      summoner: await(await smock.mock<Summoner__factory>('contracts/library/Summoner.sol:Summoner', {
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
      })).deploy()
    }

    this.commonCrafting.items
    .whenCalledWith(this.longsword)
    .returns([baseType.weapon, weaponType.longsword, 0, 0])
    this.codex.common.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns({...weapons('longsword'), id: weaponType.longsword})
    
    this.commonCrafting.items
    .whenCalledWith(this.fullPlate)
    .returns([baseType.armor, armorType.fullPlate, 0, 0])
    this.codex.common.armor.item_by_id
    .whenCalledWith(armorType.fullPlate)
    .returns({...armors('full plate'), id: armorType.fullPlate})
   
    this.commonCrafting.items
    .whenCalledWith(this.shield)
    .returns([baseType.armor, armorType.heavyWoodShield, 0, 0])
    this.codex.common.armor.item_by_id
    .whenCalledWith(armorType.heavyWoodShield)
    .returns({...armors('shield, heavy wooden'), id: armorType.heavyWoodShield})

    this.masterwork.items.items
    .whenCalledWith(this.longsword)
    .returns([baseType.weapon, weaponType.longsword, 0, 0])
    this.codex.masterwork.weapons.item_by_id
    .whenCalledWith(weaponType.longsword)
    .returns({
      ...weapons('longsword', true), 
      id: weaponType.longsword
    })

    this.masterwork.items.items
    .whenCalledWith(this.fullPlate)
    .returns([baseType.armor, armorType.fullPlate, 0, 0])
    this.codex.masterwork.armor.item_by_id
    .whenCalledWith(armorType.fullPlate)
    .returns({
      ...armors('full plate'), 
      id: armorType.fullPlate,
      name: "Masterwork Full Plate", 
      penalty: -5,
      cost: ethers.utils.parseEther('1650')
    })

    this.codex.masterwork.weapons.get_attack_bonus
    .returns(1)

    this.equipment.codexes
    .whenCalledWith(this.commonCrafting.address, 2)
    .returns(this.codex.common.armor.address)

    this.equipment.codexes
    .whenCalledWith(this.commonCrafting.address, 3)
    .returns(this.codex.common.weapons.address)

    this.equipment.codexes
    .whenCalledWith(this.masterwork.items.address, 2)
    .returns(this.codex.masterwork.armor.address)

    this.equipment.codexes
    .whenCalledWith(this.masterwork.items.address, 3)
    .returns(this.codex.masterwork.weapons.address)
  })

  it('computes hit points', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 0, 12, 0, 0, 0])

    const hp = await this.library.summoner.hit_points(this.summoner)
    expect(hp).to.eq(35)
  })

  it('computes minimum armor class', async function () {
    const ac = await this.library.summoner._armor_class_test_wrapper(this.summoner, 0, ethers.constants.AddressZero, 0, ethers.constants.AddressZero)
    expect(ac).to.equal(9)
  })

  it('computes armor class without armor', async function () {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    const ac = await this.library.summoner._armor_class_test_wrapper(this.summoner, 0, ethers.constants.AddressZero, 0, ethers.constants.AddressZero)
    expect(ac).to.equal(11)
  })

  it('computes armor class with armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 10, 0, 0, 0, 0])

    const ac = await this.library.summoner._armor_class_test_wrapper(this.summoner, this.fullPlate, this.commonCrafting.address, 0, ethers.constants.AddressZero)
    expect(ac).to.equal(18)
  })

  it('computes armor class with armor and shield', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 12, 0, 0, 0, 0])

    const ac = await this.library.summoner._armor_class_test_wrapper(
      this.summoner, 
      this.fullPlate, 
      this.commonCrafting.address, 
      this.shield, 
      this.commonCrafting.address
    )

    expect(ac).to.equal(21)
  })

  it('computes armor class bonus for unarmored monks', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.monk)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([0, 10, 0, 0, 12, 0])

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    const ac = await this.library.summoner._armor_class_test_wrapper(
      this.summoner,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero
    )

    expect(ac).to.eq(12)
  })

  it('computes armor check penalty for non-proficient armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    const acp = await this.library.summoner._armor_check_penalty_wrapper(this.summoner, this.fullPlate, this.commonCrafting.address);
    expect(acp).to.eq(-6)
  })

  it('computes armor check penalty for non-proficient masterwork armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    const acp = await this.library.summoner._armor_check_penalty_wrapper(this.summoner, this.fullPlate, this.masterwork.items.address);
    expect(acp).to.eq(-5)
  })

  it('computes armor check penalty for proficient armor', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    const acp = await this.library.summoner._armor_check_penalty_wrapper(this.summoner, this.fullPlate, this.commonCrafting.address);
    expect(acp).to.eq(0)
  })

  it('computes unarmed attack', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero,
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.attack_bonus).to.eq(5)
    expect(attack.damage_dice_sides).to.eq(3)
  })

  it('computes damage bonus for unarmed monks', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.monk)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.damage_dice_sides).to.eq(8)
  })

  it('computes non-proficient armed attack', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.wizard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      this.longsword, this.commonCrafting.address,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero,
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.attack_bonus).to.eq(-2)
  })

  it('computes non-proficient armed attack with non-proficient armor', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.wizard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      this.longsword, this.commonCrafting.address,
      this.fullPlate, this.commonCrafting.address, 
      this.shield, this.commonCrafting.address
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.attack_bonus).to.eq(-10)
  })

  it('computes proficient armed attack with proficient armor', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      this.longsword, this.commonCrafting.address,
      this.fullPlate, this.commonCrafting.address,
      this.shield, this.commonCrafting.address
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.attack_bonus).to.eq(5)
  })

  it('computes multiple attacks for experienced fighters', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(6)

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero
    )

    const attacks = unpackAttacks(attacksPack)
    expect(attacks.length).to.eq(2)
  })

  it('computes higher attack bonus for masterwork weapons', async function() {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)

    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([10, 0, 0, 0, 0, 0])

    const attacksPack = await this.library.summoner._attacks_test_wrapper(
      this.summoner, 
      this.longsword, this.masterwork.items.address,
      0, ethers.constants.AddressZero,
      0, ethers.constants.AddressZero
    )

    const attack = unpackAttacks(attacksPack)[0]
    expect(attack.attack_bonus).to.eq(6)
  })

  it('computes weapon attack modifier', async function() {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([14, 12, 0, 0, 0, 0])
    expect(await this.library.summoner.weapon_attack_modifier(this.summoner, enumberance.unarmed))
    .to.eq(2)
    expect(await this.library.summoner.weapon_attack_modifier(this.summoner, enumberance.lightMelee))
    .to.eq(2)
    expect(await this.library.summoner.weapon_attack_modifier(this.summoner, enumberance.oneHanded))
    .to.eq(2)
    expect(await this.library.summoner.weapon_attack_modifier(this.summoner, enumberance.twoHanded))
    .to.eq(2)
    expect(await this.library.summoner.weapon_attack_modifier(this.summoner, enumberance.ranged))
    .to.eq(1)
  })

  it('computes weapon damage modifier', async function() {
    this.attributes.ability_scores
    .whenCalledWith(this.summoner)
    .returns([14, 12, 0, 0, 0, 0])
    expect(await this.library.summoner.weapon_damage_modifier(this.summoner, enumberance.unarmed))
    .to.eq(2)
    expect(await this.library.summoner.weapon_damage_modifier(this.summoner, enumberance.lightMelee))
    .to.eq(2)
    expect(await this.library.summoner.weapon_damage_modifier(this.summoner, enumberance.oneHanded))
    .to.eq(2)
    expect(await this.library.summoner.weapon_damage_modifier(this.summoner, enumberance.twoHanded))
    .to.eq(3)
    expect(await this.library.summoner.weapon_damage_modifier(this.summoner, enumberance.ranged))
    .to.eq(1)
  })

  it('computes basic attack bonus', async function () {
    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.fighter)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([5, 0, 0, 0])

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(6)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([6, 1, 0, 0])

    this.rarity.level // 11th level ~ October 2024
    .whenCalledWith(this.summoner)
    .returns(11)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([11, 6, 1, 0])

    this.rarity.level // 16th level ~ August 2030
    .whenCalledWith(this.summoner)
    .returns(16)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([16, 11, 6, 1])

    this.rarity.class
    .whenCalledWith(this.summoner)
    .returns(classes.bard)

    this.rarity.level
    .whenCalledWith(this.summoner)
    .returns(5)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([3, 0, 0, 0])

    this.rarity.level // 8th level ~ December 2022
    .whenCalledWith(this.summoner)
    .returns(8)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([6, 1, 0, 0])

    this.rarity.level // 15th level ~ February 2029
    .whenCalledWith(this.summoner)
    .returns(15)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([11, 6, 1, 0])

    this.rarity.level // 20th level ~ July 2038
    .whenCalledWith(this.summoner)
    .returns(20)
    expect(await this.library.summoner.base_attack_bonus(this.summoner)).to.deep.eq([15, 10, 5, 0])
  })

  it('tests proficiencies', async function() {
    const fighter = randomId()
    this.rarity.class
    .whenCalledWith(fighter)
    .returns(classes.fighter)

    expect(await this.library.summoner.is_proficient_with_weapon(fighter, weaponType.longsword, this.commonCrafting.address))
    .to.be.true

    expect(await this.library.summoner.is_proficient_with_armor(fighter, armorType.fullPlate, this.commonCrafting.address))
    .to.be.true

    expect(await this.library.summoner.is_proficient_with_armor(fighter, armorType.heavyWoodShield, this.commonCrafting.address))
    .to.be.true
  })

  it('previews loadouts', async function() {
    const fighter = randomId()
    this.rarity.class
    .whenCalledWith(fighter)
    .returns(classes.fighter)
  
    this.rarity.level
    .whenCalledWith(fighter)
    .returns(1)
  
    this.attributes.ability_scores
    .whenCalledWith(fighter)
    .returns([10, 10, 10, 0, 0, 0])

    const longsword = fakeLongsword(this.commonCrafting, fighter, this.signer)
    const fullplate = fakeFullPlateArmor(this.commonCrafting, fighter, this.signer)
    const shield = fakeHeavyWoodShield(this.commonCrafting, fighter, this.signer)
  
    const preview = await this.library.summoner.preview(
      fighter, 
      this.commonCrafting.address, longsword,
      this.commonCrafting.address, fullplate,
      this.commonCrafting.address, shield
    )
  
    expect(preview.armor_class).to.eq(20)
    expect(preview.hit_points).to.eq(10)
    expect(unpackAttacks(preview.attacks)[0].attack_bonus).to.eq(1)
  })
})