pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PrivateSaleAndVesting is Context, Ownable {
  struct VestingDetail {
    uint256 _withdrawableAmount;
    uint256 _nextWithdrawalTime;
  }
}
