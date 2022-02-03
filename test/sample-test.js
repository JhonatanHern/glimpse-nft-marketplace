const { expect } = require("chai")
const { ethers } = require("hardhat")

// only for testing, has no relationship with the actual safe
const testSafe = '0x42261b574358b4EE8ad3D43FB416B4D82D61CD93'

describe("Marketplace", function () {
  let NFT, nft, TestERC20, testToken
  beforeEach(async () => {
    TestERC20 = await ethers.getContractFactory("TestERC20")
    testToken = await TestERC20.deploy()
    NFT = await ethers.getContractFactory("Marketplace")
    nft = await NFT.deploy(testToken.address, 10, testSafe)
  })
  it("Should allow me to mint a token", async function () {
    const id = await nft.mint('MyHash', 0)
    expect(id.value).eq(0)
  })
})
