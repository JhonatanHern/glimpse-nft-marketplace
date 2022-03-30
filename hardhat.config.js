require('dotenv').config();
require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
require('hardhat-deploy');
require('solidity-coverage');
require('hardhat-gas-reporter');
require('hardhat-deploy-ethers');
require('chai');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

let mnemonic = process.env.MNEMONIC
  ? process.env.MNEMONIC
  : 'test test test test test test test test test test test test';

module.exports = {
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      accounts: {
        mnemonic,
      },
    },
    bsc: {
      url: 'https://bsc-dataseed.binance.org/',
      accounts: { mnemonic: process.env.MNEMONIC },
    },
    testBSC: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      accounts: { mnemonic: process.env.MNEMONIC },
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API,
  },
  namedAccounts: {
    deployer: 0,
    owner: '0x5a46AB557E9F579A02Cc4C40e51990e6aC7164e1',
    feeRecipient: 1,
    user: 2,
    userNotRegister: 3,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 50,
    enabled: process.env.REPORT_GAS ? true : false,
    coinmarketcap: process.env.CMC_API_KEY,
    excludeContracts: ['mocks/'],
  },
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  mocha: {
    timeout: 240000,
  },
};
