const hre = require("hardhat");

const tokenAddress = '0x0802727531845C9eE9c5b8F04E6B6D1D6DF92067'

async function main() {
  const Marketplace = await hre.ethers.getContractFactory("Marketplace")
  const marketplace = await Marketplace.deploy(tokenAddress)
  await marketplace.deployed()
  console.log("Marketplace deployed to:", marketplace.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  });
