pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TokenSaleAndVesting is Context, Ownable {
  struct VestingDetail {
    uint256 _withdrawalTime;
    uint256 _withdrawalAmount;
  }

  IERC20 _paymentToken;
  address payable _foundationAddress;
  uint256 _rate;
  uint256 _endTime;
  uint256 _daysBeforeWithdrawal;
  uint256 _totalVested;
  bool _started;

  mapping(address => VestingDetail) _vestingDetails;

  modifier onlyFoundationAddress() {
    require(
      _msgSender() == _foundationAddress,
      "VeFiTokenVest: Only foundation address can call this function"
    );
    _;
  }

  constructor(
    address paymentToken_,
    uint256 rate_,
    address payable foundationAddress_
  ) Ownable() {
    _paymentToken = IERC20(paymentToken_);
    _rate = rate_;
    _foundationAddress = foundationAddress_;
  }

  function startSale(uint256 _daysToLast, uint256 daysBeforeWithdrawal_)
    external
    onlyFoundationAddress
  {
    uint256 _time = block.timestamp;
    _endTime = _time + (_daysToLast * 1 days);
    _daysBeforeWithdrawal = (daysBeforeWithdrawal_ * 1 days);
    _started = true;
  }

  function extendSale(uint256 _daysToExtendSaleBy)
    external
    onlyFoundationAddress
  {
    require(
      _started,
      "VeFiTokenVest: Sale must be started before the end date can be extended"
    );
    _endTime = _endTime + (_daysToExtendSaleBy * 1 days);
  }

  function buyAndVest() public payable {
    uint256 _currentTime = block.timestamp;

    require(_started, "VeFiTokenVest: Sale not started yet");
    require(_endTime > _currentTime, "VeFiTokenVest: Sale has ended");

    address _vestor = _msgSender();
    uint256 _vestable = (msg.value * 10**18) / _rate;

    require(
      (_totalVested + _vestable) <= _paymentToken.balanceOf(address(this)),
      "VeFiTokenVest: Cannot buy and vest as allocation is not enough"
    );

    VestingDetail storage vestingDetail = _vestingDetails[_vestor];
    vestingDetail._withdrawalAmount =
      vestingDetail._withdrawalAmount +
      _vestable;
    vestingDetail._withdrawalTime = block.timestamp + _daysBeforeWithdrawal;
    _totalVested = _totalVested + _vestable;
  }

  function withdraw() external {
    VestingDetail storage vestingDetail = _vestingDetails[_msgSender()];

    require(
      _paymentToken.balanceOf(address(this)) >= vestingDetail._withdrawalAmount,
      "VeFiTokenVest: Not enough tokens to sell. Please reach out to the foundation concerning this"
    );
    require(
      _paymentToken.transfer(_msgSender(), vestingDetail._withdrawalAmount),
      "VeFiTokenVest: Could not transfer tokens"
    );
  }

  function withdrawBNB() external onlyFoundationAddress {
    uint256 _balance = address(this).balance;
    _foundationAddress.transfer(_balance);
  }

  receive() external payable {
    buyAndVest();
  }
}
