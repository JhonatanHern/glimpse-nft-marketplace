const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("Marketplace", function () {
  let NFT, nft
  beforeEach(() => {
    NFT = await ethers.getContractFactory("Marketplace")
    nft = await nft.deploy()
  })
  it("Should allow me to mint a token", async function () {
    await nft.mint('MyHash')
    
  })
})
