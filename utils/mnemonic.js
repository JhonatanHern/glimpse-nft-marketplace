const mnemonicFunc = (mnemonic, account) => {
  const walletMnemonic = ethers.Wallet.fromMnemonic(
    mnemonic,
    `m/44'/60'/0'/0/${account}`
  );
  return {
    publicKey: walletMnemonic.address,
    privateKey: walletMnemonic.privateKey,
  };
};

module.exports = { mnemonicFunc };
