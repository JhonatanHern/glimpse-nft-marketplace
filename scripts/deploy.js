const hre = require('hardhat');

const tokenAddress = '0x57e2d63ca5131bf7c44f7639975c53142ab9a761';
const safe = '0x42261b574358b4EE8ad3D43FB416B4D82D61CD93';

async function main() {
  const Marketplace = await hre.ethers.getContractFactory('Marketplace');
  const marketplace = await Marketplace.deploy(tokenAddress, 10, safe);
  await marketplace.deployed();
  console.log('Marketplace deployed to:', marketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
