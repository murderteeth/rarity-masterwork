import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

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
  typechain: {
    outDir: "./typechain",
    target: "ethers-v5"
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
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.FTMSCAN_API_KEY,
  },
};

export default config;
