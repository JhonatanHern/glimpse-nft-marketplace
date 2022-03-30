const CONTRACT_NAME = 'Marketplace';

const tokenAddress = '0x57e2d63ca5131bf7c44f7639975c53142ab9a761';
const safe = '0x42261b574358b4EE8ad3D43FB416B4D82D61CD93';
const masterWallet = '0x1c9458660891A6C6ad27bc9e348B7C285c149014';

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy(CONTRACT_NAME, {
    from: deployer,
    log: true,
    args: [tokenAddress, 10, safe, masterWallet],
  });
};

module.exports.tags = [CONTRACT_NAME];
