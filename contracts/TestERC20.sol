//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20{
  constructor() ERC20("TST", "TEST") {
    _mint(msg.sender, 1000_000);
  }
}
