import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import '@typechain/hardhat/dist/type-extensions';
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
      }
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
        url: "https://weathered-aged-mountain.fantom.quiknode.pro/f005eca18b3311849dab86cc1dd8fc7a6d54e611/"
      }
    },
    mainnet: {
      url: "https://rpc.ftm.tools",
      accounts: [process.env.PRIVATE_KEY || ""],
      timeout: 120_000
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    excludeContracts: [
      "contracts/core/",
      "contracts/extended/",
      "@openzeppelin/contracts/token/ERC721/ERC721.sol"
    ]
  },
  etherscan: {
    apiKey: process.env.FTMSCAN_API_KEY,
  },
};

export default config;
