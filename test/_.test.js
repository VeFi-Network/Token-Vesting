const { expectRevert, time } = require("@openzeppelin/test-helpers");
const BigNumber = web3.BigNumber;
const MockToken = artifacts.require("MockToken");
const SeedSaleAndVesting = artifacts.require("SeedSaleAndVesting");
const PrivateSaleAndVesting = artifacts.require("PrivateSaleAndVesting");
const BN = require("bignumber.js");

require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

contract("SeedSaleAndVesting", accounts => {
  let seedSale;
  let token;
  const daysBeforeStart = 21;
  const saleEndTime = 10;
  const withdrawalTime = 30;

  const [beneficiary1, beneficiary2, beneficiary3] = [
    accounts[0],
    accounts[1],
    accounts[3]
  ];

  before(async () => {
    await time.advanceBlock();
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
      seedSale.startSale(daysBeforeStart, saleEndTime, withdrawalTime, {
        from: beneficiary1
      }),
      "VeFiTokenVest: Only foundation address can call this function"
    );
  });

  it("should permit only foundation address to start sale", async () => {
    await seedSale.startSale(daysBeforeStart, saleEndTime, withdrawalTime, {
      from: beneficiary2
    });
    const remainingTime = await seedSale.getRemainingTime();
    remainingTime
      .toString()
      .should.be.bignumber.equal(60 * 60 * 24 * (10 + 21));
  });

  it("should only permit to buy and vest after sale has been started", async () => {
    await expectRevert(
      seedSale.buyAndVest({
        from: beneficiary3,
        value: web3.utils.toWei("0.000002")
      }),
      "VeFiTokenVest: Sale not started yet"
    );
  });

  it("should allow anyone to buy and vest", async () => {
    await time.increase(time.duration.days(21));
    await seedSale.buyAndVest({
      from: beneficiary3,
      value: web3.utils.toWei("0.000002")
    });
    const vestingDetail = await seedSale.getVestingDetail(beneficiary3);
    vestingDetail._withdrawalAmount.toString().should.be.bignumber.equal(1e16);
  });

  it("should not allow withdrawal before 2 month cliff", async () => {
    await expectRevert(
      seedSale.withdraw({ from: beneficiary3 }),
      "VeFiTokenVest: Token withdrawal before 2 month cliff"
    );
  });

  it("should withdraw 5%", async () => {
    const currentWithdrawalAmount = (
      await seedSale.getVestingDetail(beneficiary3)
    )._withdrawalAmount;
    await time.increase(time.duration.days(10).add(time.duration.days(61)));
    await seedSale.withdraw({ from: beneficiary3 });
    const newWithdrawalAmount = (await seedSale.getVestingDetail(beneficiary3))
      ._withdrawalAmount;
    assert.isTrue(
      new BN.BigNumber(newWithdrawalAmount).isEqualTo(
        new BN.BigNumber(currentWithdrawalAmount).minus(
          await token.balanceOf(beneficiary3)
        )
      )
    );
  });

  it("should throw error if address tries to withdraw before withdrawal time", async () => {
    await expectRevert(
      seedSale.withdraw({ from: beneficiary3 }),
      "VeFiTokenVest: It is not time for withdrawal"
    );
  });

  it("should only allow foundation address to withdraw BNB", async () => {
    await expectRevert(
      seedSale.withdrawBNB({ from: beneficiary3 }),
      "VeFiTokenVest: Only foundation address can call this function"
    );
  });

  it("should allow foundation address to withdraw BNB", async () => {
    const currentBalance = await web3.eth.getBalance(beneficiary2);
    await seedSale.withdrawBNB({ from: beneficiary2 });
    const newBalance = await web3.eth.getBalance(beneficiary2);
    assert.isTrue(
      new BN.BigNumber(newBalance).lt(new BN.BigNumber(currentBalance))
    );
  });

  it("should allow only foundation address to withdraw left-over tokens", async () => {
    await expectRevert(
      seedSale.withdrawLeftOverTokens({ from: beneficiary3 }),
      "VeFiTokenVest: Only foundation address can call this function"
    );
  });

  it("should allow foundation address to withdraw left-over tokens", async () => {
    const currentBalance = await token.balanceOf(beneficiary2);
    await seedSale.withdrawLeftOverTokens({ from: beneficiary2 });
    const newBalance = await token.balanceOf(beneficiary2);
    assert.isTrue(
      new BN.BigNumber(newBalance).gt(new BN.BigNumber(currentBalance))
    );
  });
});

contract("PrivateSaleAndVesting", accounts => {
  let privateSale;
  let token;
  const daysBeforeStart = 30;
  const saleEndTime = 10;
  const withdrawalTime = 30;

  const [beneficiary1, beneficiary2, beneficiary3] = [
    accounts[0],
    accounts[1],
    accounts[3]
  ];

  before(async () => {
    await time.advanceBlock();
    token = await MockToken.new(
      "MockToken",
      "Mktk",
      web3.utils.toWei("1000000")
    );
    privateSale = await PrivateSaleAndVesting.new(
      token.address,
      web3.utils.toWei("0.0002"),
      beneficiary2
    );
    await token.transfer(privateSale.address, web3.utils.toWei("1000000"));
  });

  it("should have transferred 1000000 tokens to private sale contract", async () => {
    const balance = await token.balanceOf(privateSale.address);
    assert.equal(balance, web3.utils.toWei("1000000"));
  });

  it("should not permit random address to start sale", async () => {
    await expectRevert(
      privateSale.startSale(daysBeforeStart, saleEndTime, withdrawalTime, {
        from: beneficiary1
      }),
      "VeFiTokenVest: Only foundation address can call this function"
    );
  });

  it("should permit only foundation address to start sale", async () => {
    await privateSale.startSale(daysBeforeStart, saleEndTime, withdrawalTime, {
      from: beneficiary2
    });
    const remainingTime = await privateSale.getRemainingTime();
    remainingTime
      .toString()
      .should.be.bignumber.equal(60 * 60 * 24 * (10 + 30));
  });

  it("should allow only whitelisted addresses to buy and vest", async () => {
    await time.increase(time.duration.days(30));
    await expectRevert(
      privateSale.buyAndVest({
        from: beneficiary3,
        value: web3.utils.toWei("0.000002")
      }),
      "VeFiTokenVest: Only whitelisted addresses can call this function"
    );
  });

  it("should allow foundation address to whitelist addresses", async () => {
    await privateSale.whitelistForSale([beneficiary1, beneficiary3], {
      from: beneficiary2
    });
  });

  it("should allow whitelisted address to buy and vest", async () => {
    await privateSale.buyAndVest({
      from: beneficiary3,
      value: web3.utils.toWei("0.000002")
    });
    const vestingDetail = await privateSale.getVestingDetail(beneficiary3);
    vestingDetail._withdrawalAmount.toString().should.be.bignumber.equal(1e16);
  });
});
