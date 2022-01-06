pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';

contract MockToken is Context, Ownable, ERC20 {
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 amount_
  ) ERC20(name_, symbol_) {
    _mint(_msgSender(), amount_);
  }
}
