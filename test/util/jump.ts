import { ethers, network } from 'hardhat'

export async function jumpOneDay() {
  await network.provider.send("evm_increaseTime", [1 * 24 * 60 * 60]);
  await network.provider.send("evm_mine");
}

export async function jumpOneMinute() {
  await network.provider.send("evm_increaseTime", [1 * 60]);
  await network.provider.send("evm_mine");
}