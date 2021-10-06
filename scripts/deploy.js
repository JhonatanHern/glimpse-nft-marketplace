const hre = require("hardhat");

const tokenAddress = '0x0892D833Faf5675D3C1501754e37121DE93390D1'

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
