const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
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

  const [beneficiary1, beneficiary2, beneficiary3, beneficiary4] = [
    accounts[0],
    accounts[1],
    accounts[3],
    accounts[4]
  ];

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

  it("should have transferred 1000000 tokens to seed sale contract", async () => {
    const balance = await token.balanceOf(seedSale.address);
    assert.equal(balance, web3.utils.toWei("1000000"));
  });

  it("should not permit random address to start sale", async () => {
    await expectRevert(
      seedSale.startSale(10, 30, { from: beneficiary1 }),
      "VeFiTokenVest: Only foundation address can call this function"
    );
  });

  it("should permit only foundation address to start sale", async () => {
    await seedSale.startSale(10, 30, { from: beneficiary2 });
    const remainingTime = await seedSale.getRemainingTime();
    remainingTime.toString().should.be.bignumber.equal(60 * 60 * 24 * 10);
  });

  it("should allow anyone to buy and vest", async () => {
    await seedSale.buyAndVest({
      from: beneficiary3,
      value: web3.utils.toWei("0.000002")
    });
    const vestingDetail = await seedSale.getVestingDetail(beneficiary3);
    vestingDetail._withdrawalAmount.toString().should.be.bignumber.equal(1e16);
  });
});
