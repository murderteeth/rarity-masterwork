import chai, { expect } from 'chai'
import { ethers } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { randomId } from '../util'
import { fakeAttributes, fakeFeats, fakeRandom, fakeRarity, fakeSkills } from '../util/fakes'
import { Armor__factory, Feats__factory, Random__factory, Rarity__factory, SkillCheck__factory, Skills__factory } from '../../typechain/library'
import { RarityAdventure2__factory } from '../../typechain/core/factories/RarityAdventure2__factory'
import { skills } from '../util/skills'
import { feats } from '../util/feats'

chai.use(smock.matchers)

describe.only('Core: Adventure (II)', function () {
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
        })).deploy()).address
      }
    })).deploy()

    this.summoner = () => {
      const summoner = randomId()
      this.core.rarity.ownerOf
      .whenCalledWith(summoner)
      .returns(this.signer.address)
      return summoner
    }
  })

  it('starts new adventures', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    expect((await this.adventure.adventures(token))['started']).to.be.gt(0)
    expect(await this.adventure.active_adventures(summoner)).to.eq(token)
  })

  it('reverts if you start more than one active adventure', async function () {
    const summoner = this.summoner()
    await expect(this.adventure.start(summoner)).to.not.be.reverted
    await expect(this.adventure.start(summoner)).to.be.revertedWith('active_adventures[summoner] != 0')
  })

  it('authorizes the owner of an adventure', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    expect(await this.adventure.isApprovedOrOwnerOfAdventure(token)).to.be.true
  })

  it('authorizes address approved for an adventure', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)

    const approvedSigner = this.signers[1]
    const signersConnection = await this.adventure.connect(approvedSigner)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(token)).to.be.false
    await this.adventure.approve(approvedSigner.address, token)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(token)).to.be.true
  })

  it('authorizes address approved for all of the owner\'s adventures', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)

    const approvedSigner = this.signers[1]
    const signersConnection = await this.adventure.connect(approvedSigner)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(token)).to.be.false
    await this.adventure.setApprovalForAll(approvedSigner.address, true)
    expect(await signersConnection.isApprovedOrOwnerOfAdventure(token)).to.be.true
  })

  it('fails to sense the farmer\'s motives', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)

    await expect(this.adventure.sense_farmers_motive(token))
    .to.emit(this.adventure, 'SenseFarmersMotive')
    .withArgs(token, 1, 0)

    const adventure = await this.adventure.adventures(token)
    expect(adventure.farmers_bluff_checked).to.be.true
    expect(adventure.farmers_key).to.be.false
  })

  it('senses the farmer\'s motives', async function () {
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)

    this.core.attributes.ability_scores
    .whenCalledWith(summoner)
    .returns([0, 0, 0, 0, 10, 0])

    const skillRanks = Array(36).fill(0)
    skillRanks[skills.sense_motive] = 1
    this.core.skills.get_skills
    .whenCalledWith(summoner)
    .returns(skillRanks)

    const featFlags = Array(100).fill(false)
    featFlags[feats.negotiator] = true
    this.core.feats.get_feats
    .whenCalledWith(summoner)
    .returns(featFlags)

    this.codex.random.dn.returns(17)

    await expect(this.adventure.sense_farmers_motive(token))
    .to.emit(this.adventure, 'SenseFarmersMotive')
    .withArgs(token, 17, 20)

    const adventure = await this.adventure.adventures(token)
    expect(adventure.farmers_bluff_checked).to.be.true
    expect(adventure.farmers_key).to.be.true
  })

  it('reverts if you sense motive more than once per adventure', async function (){
    const summoner = this.summoner()
    const token = await this.adventure.next_token()
    await this.adventure.start(summoner)
    await expect(this.adventure.sense_farmers_motive(token)).to.not.be.reverted
    await expect(this.adventure.sense_farmers_motive(token)).to.be.revertedWith('farmers_bluff_checked == true')
  })

  it.skip('prevents sensing the farmer\'s motives after combat has begun', async function () {
    // TODO
  })

  it.skip('equips weapons and armor', async function () {

  })

  it.skip('prevents equipping if the adventure hasn\'t begun', async function () {

  })

  it.skip('prevents equipping if combat has begun', async function () {

  })

  it.skip('enters the barn', async function () {

  })

  it.skip('prevents entering the barn more than once', async function () {

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