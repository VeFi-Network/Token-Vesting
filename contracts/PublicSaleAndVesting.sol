pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PublicSaleAndVesting is Context, Ownable {
  struct VestingDetail {
    uint256 _withdrawalTime;
    uint256 _withdrawalAmount;
    uint256 _lockDuration;
  }

  IERC20 _paymentToken;
  address payable _foundationAddress;
  uint256 _rate;
  uint256 _startTime;
  uint256 _endTime;
  uint256 _daysBeforeWithdrawal;
  uint256 _totalVested;
  bool _initialized;

  mapping(address => VestingDetail) _vestingDetails;

  modifier onlyFoundationAddress() {
    require(
      _msgSender() == _foundationAddress,
      "VeFiTokenVest: Only foundation address can call this function"
    );
    _;
  }

  event TokenSaleStarted(uint256 _startTime);
  event TokenSaleExtended(uint256 _extension);
  event TokensBoughtAndVested(uint256 _vested, uint256 _totalVesting);
  event TokensWithdrawn(uint256 _amount, uint256 _inVesting);
  event RateChanged(uint256 _newRate);

  constructor(
    address paymentToken_,
    uint256 rate_,
    address payable foundationAddress_
  ) Ownable() {
    _paymentToken = IERC20(paymentToken_);
    _rate = rate_;
    _foundationAddress = foundationAddress_;
  }

  /** @dev Start the token sale. Can only be called by the foundation
   *  @param _daysToLast The number of days the token sale should last
   *  @param daysBeforeWithdrawal_ The number of days before tokens can be withdrawn after vesting
   */
  function startSale(
    uint256 _daysBeforeStart,
    uint256 _daysToLast,
    uint256 daysBeforeWithdrawal_
  ) external onlyFoundationAddress {
    uint256 _time = block.timestamp;
    _startTime = _time + (_daysBeforeStart * 1 days);
    _endTime = _startTime + (_daysToLast * 1 days);
    _daysBeforeWithdrawal = (daysBeforeWithdrawal_ * 1 days);
    _initialized = true;
    emit TokenSaleStarted(_time);
  }

  /** @dev Extend the token sale
   *  @param _daysToExtendSaleBy The number of days to extend the end date by
   */
  function extendSale(uint256 _daysToExtendSaleBy)
    external
    onlyFoundationAddress
  {
    require(
      block.timestamp >= _startTime,
      "VeFiTokenVest: Sale must be started before the end date can be extended"
    );
    _endTime = _endTime + (_daysToExtendSaleBy * 1 days);

    emit TokenSaleExtended(_daysToExtendSaleBy);
  }

  /** @dev Function to be called by intending vestor. Amount of BNB to spend is sent to this function
   */
  function buyAndVest() public payable {
    uint256 _currentTime = block.timestamp;

    require(_currentTime >= _startTime, "VeFiTokenVest: Sale not started yet");
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
    vestingDetail._lockDuration = block.timestamp + (2 * 365 days);
    _totalVested = _totalVested + _vestable;

    emit TokensBoughtAndVested(vestingDetail._withdrawalAmount, _totalVested);
  }

  /** @dev Withdrawal function. Can only be called after vesting period has elapsed
   */
  function withdraw() external {
    uint256 _cliff = _endTime + (60 * 1 days);
    require(
      block.timestamp > _cliff,
      "VeFiTokenVest: Token withdrawal before 2 month cliff"
    );
    VestingDetail storage vestingDetail = _vestingDetails[_msgSender()];
    uint256 _withdrawable;

    require(
      vestingDetail._withdrawalTime != 0,
      "VeFiTokenVest: Withdrawal not possible"
    );

    if (block.timestamp >= vestingDetail._lockDuration) {
      _withdrawable = vestingDetail._withdrawalAmount;
    } else {
      _withdrawable = (vestingDetail._withdrawalAmount * 5) / 100;
    }

    require(
      (block.timestamp >= vestingDetail._withdrawalTime),
      "VeFiTokenVest: It is not time for withdrawal"
    );
    require(
      _paymentToken.balanceOf(address(this)) >= _withdrawable,
      "VeFiTokenVest: Not enough tokens to sell. Please reach out to the foundation concerning this"
    );
    require(
      _paymentToken.transfer(_msgSender(), _withdrawable),
      "VeFiTokenVest: Could not transfer tokens"
    );

    vestingDetail._withdrawalAmount =
      vestingDetail._withdrawalAmount -
      _withdrawable;
    vestingDetail._withdrawalTime = block.timestamp <
      vestingDetail._lockDuration
      ? block.timestamp + _daysBeforeWithdrawal
      : 0;

    if (block.timestamp >= vestingDetail._lockDuration)
      vestingDetail._lockDuration = 0;

    _totalVested = _totalVested - _withdrawable;

    emit TokensWithdrawn(_withdrawable, _totalVested);
  }

  /** @dev Function to withdraw BNB deposited during sale. Can only be called by the foundation
   */
  function withdrawBNB() external onlyFoundationAddress {
    uint256 _balance = address(this).balance;
    _foundationAddress.transfer(_balance);
  }

  /** @dev Function to withdraw left-over tokens. Can only be called by the foundation and after the sale has ended.
   */
  function withdrawLeftOverTokens() external onlyFoundationAddress {
    require(
      block.timestamp >= _endTime,
      "VeFiTokenVest: Left over tokens can only be withdrawn after sale"
    );
    require(
      _paymentToken.balanceOf(address(this)) > 0,
      "VeFiTokenVest: No left over tokens to withdraw"
    );
    require(
      _paymentToken.transfer(
        _foundationAddress,
        _paymentToken.balanceOf(address(this))
      ),
      "VeFiTokenVest: Could not withdraw left over tokens"
    );
  }

  /** @dev Set the rate for the sale
   *  @param rate_ The rate to be set
   */
  function setRate(uint256 rate_) external onlyFoundationAddress {
    require(rate_ > 0, "VeFiTokenVest: Rate must be greater than 0");
    _rate = rate_;

    emit RateChanged(_rate);
  }

  /** @dev Set foundation address. Can only be called by contract owner
   *  @param foundationAddress_ address to set
   */
  function setFoundationAddress(address payable foundationAddress_)
    external
    onlyOwner
  {
    require(
      foundationAddress_ != address(0),
      "VeFiTokenVest: Set zero address as foundation address"
    );
    _foundationAddress = foundationAddress_;
  }

  /** @dev Get time remaining before sale starts
   */
  function getTimeBeforeStart() public view returns (uint256) {
    uint256 _currentTime = block.timestamp;

    if (_startTime < _currentTime) return 0;

    return _startTime - _currentTime;
  }

  /** @dev Get time remaining before sale ends
   */
  function getRemainingTime() public view returns (uint256) {
    uint256 _currentTime = block.timestamp;

    if (_endTime < _currentTime) return 0;

    return _endTime - _currentTime;
  }

  /** @dev Returns a boolean value indication whether the counter has been started or not
   */
  function isInitialized() external view returns (bool) {
    return _initialized;
  }

  /** @dev Get vesting detail of address
   *  @param _vestor Address for which to view vesting detail
   */
  function getVestingDetail(address _vestor)
    external
    view
    returns (VestingDetail memory _detail)
  {
    return _vestingDetails[_vestor];
  }

  /** @dev Returns the presently set rate
   */
  function getRate() external view returns (uint256) {
    return _rate;
  }

  receive() external payable {
    buyAndVest();
  }
}
