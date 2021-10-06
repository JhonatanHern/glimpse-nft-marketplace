require("@nomiclabs/hardhat-waffle")
require("dotenv").config()

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: process.env.RINKEBY_ALCHEMY_KEY,
      accounts: { mnemonic: process.env.MY_MNEMONIC },
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: { mnemonic: process.env.MY_MNEMONIC },
    },
    testBSC: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: { mnemonic: process.env.MY_MNEMONIC },
    }
  }
}
