const CONTRACT_NAME = 'GLIMPSE';

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy(CONTRACT_NAME, {
    from: deployer,
    log: true,
  });
};

module.exports.tags = [CONTRACT_NAME];
