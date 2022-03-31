const contract = require('../artifacts/contracts/GlimpseToken.sol/GLIMPSE.json');
const tokenAddress = '0xf4a2a3180BDeFE064DA98019c314Ce245399E2b9';
const { mnemonicFunc } = require('../utils/mnemonic');

const mnemonic = process.env.MNEMONIC;

(async () => {
  const { privateKey } = mnemonicFunc(mnemonic, 0);
  const provider = ethers.getDefaultProvider(
    'https://speedy-nodes-nyc.moralis.io/28502f735aacad0bde6341e0/bsc/testnet'
  );
  const wallet = new ethers.Wallet(privateKey, provider);

  const glms = new ethers.Contract(tokenAddress, contract.abi, wallet.provider);

  const tx = await glms
    .connect(wallet)
    .transfer(
      '0x32D67cb63316481a56E7B0c7073F5159Afb13C3b',
      ethers.utils.parseEther('360000000')
    );
  console.log(tx);
})();
