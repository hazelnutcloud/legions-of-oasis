// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Valor is ERC20 {
  constructor() ERC20("Valor", "VALOR") {}

  function mint(address to, uint256 amount) external returns (bool) {
    _mint(to, amount);
    return true;
  }

  function burn(address account, uint256 amount) external returns (bool) {
    _burn(account, amount);
    return true;
  }
}