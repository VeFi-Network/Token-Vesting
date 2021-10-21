const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { assert } = require("chai");
const BigNumber = web3.BigNumber;
const MockToken = artifacts.require("MockToken");
const SeedSaleAndVesting = artifacts.require("SeedSaleAndVesting");

require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

contract("SeedSaleAndVesting", accounts => {
  let seedSale;
  let token;

  const [beneficiary1, beneficiary2] = [accounts[0], accounts[1]];

  before(async () => {
    token = await MockToken.new(
      "MockToken",
      "Mktk",
      web3.utils.toWei("1000000")
    );
    seedSale = await SeedSaleAndVesting.new(
      token.address,
      web3.utils.toWei("0.0002"),
      beneficiary2
    );
    await token.transfer(seedSale.address, web3.utils.toWei("1000000"));
  });

  it("should have transferred 1000000 tokens to seed sale contract", () => {
    const balance = await token.balanceOf(seedSale.address);
    assert.equal(balance, web3.utils.toWei("1000000"));
  });
});
