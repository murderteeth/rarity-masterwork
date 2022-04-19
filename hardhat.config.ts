import * as dotenv from "dotenv";

import { HardhatUserConfig, task, subtask } from "hardhat/config";
import { TASK_CLEAN, TASK_COMPILE_SOLIDITY_COMPILE_JOBS, TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-abi-exporter";
import { promise as glob } from 'glob-promise'
import shell, { ShellString } from 'shelljs'

dotenv.config();

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS)
.setAction(async (_: any, __: any, runSuper: any) => {
  const paths = (await runSuper()).filter((path: string) => {
    return !(path.includes('spells/'))
  });
  return paths;
});

async function makeTypes(subfolder: string) {
  const temp = '.temp'
  shell.mkdir('-p', temp)
  const files = await glob(`artifacts/contracts/${subfolder}/**/+([a-zA-Z0-9_]).json`)
  files.forEach(file => {
    shell.cp(file, `${temp}/`)    
  })
  shell.exec(`npx typechain --target ethers-v5 --out-dir typechain/${subfolder} ${temp}/*`)
  shell.rm('-rf', temp)
}

subtask(TASK_COMPILE_SOLIDITY_COMPILE_JOBS).setAction(
  async (taskArgs, { run }, runSuper) => {
    const compileSolOutput = await runSuper(taskArgs)
    if(compileSolOutput.artifactsEmittedPerJob.length > 0) {
      await makeTypes('core')
      await makeTypes('interfaces/codex')
      await makeTypes('interfaces/core')
      await makeTypes('library')
    }
    return compileSolOutput
  },
)

task(TASK_CLEAN,
  async ({ global }: { global: boolean }, { config }, runSuper) => {
    if (global) {
      return
    }
    shell.rm('-rf', './typechain')
    await runSuper()
  },
)

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

function makeInterface(subfolder: string, abiPath: string, interfaceName: string) {
  shell.mkdir('-p', `contracts/interfaces/${subfolder}`)
  const flatJson = JSON.stringify(JSON.parse(shell.cat(`.abis/contracts/${subfolder}/${abiPath}`)))
  new ShellString(flatJson).exec(`npx abi-to-sol ${interfaceName}`).to(`contracts/interfaces/${subfolder}/${interfaceName}.sol`)
}

task('rarity-interfaces', 'Generates interfaces for Rarity contracts').setAction(async () => {
  makeInterface('core', 'attributes.sol/rarity_attributes.json', 'IRarityAttributes')
  makeInterface('core', 'base.sol/codex.json', 'IRarityBase')
  makeInterface('core', 'feats.sol/rarity_feats.json', 'IRarityFeats')
  makeInterface('core', 'gold.sol/rarity_gold.json', 'IRarityGold')
  makeInterface('core', 'namesv2.sol/rarity_names.json', 'IRarityNames2')
  makeInterface('core', 'rarity_crafting_skills.sol/rarity_crafting_skills.json', 'IRarityCraftingSkills')
  makeInterface('core', 'rarity_crafting_common.sol/rarity_crafting.json', 'IRarityCommonCrafting')
  makeInterface('core', 'rarity_crafting-materials-1.sol/rarity_crafting_materials.json', 'IRarityCraftingMaterials')
  makeInterface('core', 'rarity_crafting-materials-2.sol/rarity_crafting_materials_2.json', 'IRarityCraftingMaterials2')
  makeInterface('core', 'rarity_adventure-2.sol/rarity_adventure_2.json', 'IRarityAdventure2')
  makeInterface('core', 'rarity.sol/rarity.json', 'IRarity')
  makeInterface('core', 'skills.sol/rarity_skills.json', 'IRaritySkills')
  makeInterface('core', 'wRGLD.sol/wrapped_rarity_gold.json', 'IRarityWGold')

  makeInterface('codex', 'codex-base-random-2.sol/codex.json', 'IRarityCodexBaseRandom2')
  makeInterface('codex', 'codex-base-random.sol/codex.json', 'IRarityCodexBaseRandom')
  makeInterface('codex', 'codex-class-skills.sol/codex.json', 'IRarityCodexClassSkills')
  makeInterface('codex', 'codex-conditions.sol/codex.json', 'IRarityCodexConditions')
  makeInterface('codex', 'codex-feats-1.sol/codex.json', 'IRarityCodexFeats1')
  makeInterface('codex', 'codex-feats-2.sol/codex.json', 'IRarityCodexFeats2')
  makeInterface('codex', 'codex-gambits.sol/gambits.json', 'IRarityCodexGambits')
  makeInterface('codex', 'codex-items-armor.sol/codex.json', 'IRarityCodexCommonArmor')
  makeInterface('codex', 'codex-items-armor-masterwork.sol/codex.json', 'IRarityCodexMasterworkArmor')
  makeInterface('codex', 'codex-items-goods.sol/codex.json', 'IRarityCodexCommonGoods')
  makeInterface('codex', 'codex-items-tools.sol/codex.json', 'IRarityCodexCommonTools')
  makeInterface('codex', 'codex-items-tools-masterwork.sol/codex.json', 'IRarityCodexMasterworkTools')
  makeInterface('codex', 'codex-items-weapons-2.sol/codex.json', 'IRarityCodexCommonWeapons')
  makeInterface('codex', 'codex-items-weapons-masterwork.sol/codex.json', 'IRarityCodexMasterworkWeapons')
  makeInterface('codex', 'codex-skills.sol/codex.json', 'IRarityCodexSkills')
  makeInterface('codex', 'codex-crafting-skills.sol/codex.json', 'IRarityCodexCraftingSkills')
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.7",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"]
        }
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    }
  },
  paths: {
    sources: "./contracts"
  },
  networks: {
    hardhat: {
      loggingEnabled: false,
      allowUnlimitedContractSize: true,
      forking: {
        url: process.env.FTMRPC || "https://rpc.ftm.tools"
      }
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.FTMSCAN_API_KEY,
  },
  abiExporter: {
    path: '.abis',
    runOnCompile: true,
    clear: true
  }
};

export default config;
