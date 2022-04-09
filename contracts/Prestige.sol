// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Prestige is ERC20 {
  constructor() ERC20("Prestige", "PRSTG") {}

  function mint(address to, uint256 amount) external returns (bool) {
    _mint(to, amount);
    return true;
  }
}