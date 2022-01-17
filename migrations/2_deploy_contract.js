const SeedSaleAndVesting = artifacts.require('InitialPublicSaleAndVesting');
const PrivateSaleAndVesting = artifacts.require('PrivateSaleAndVesting');

const { FOUNDATION_ADDRESS, PAYMENT_TOKEN } = require('../_env');

module.exports = async deployer => {
  const seedSale = await deployer.deploy(
    SeedSaleAndVesting,
    PAYMENT_TOKEN,
    web3.utils.toWei('0.00017'),
    FOUNDATION_ADDRESS
  );
  const privateSale = await deployer.deploy(
    PrivateSaleAndVesting,
    PAYMENT_TOKEN,
    web3.utils.toWei('0.00017'),
    FOUNDATION_ADDRESS
  );
};
