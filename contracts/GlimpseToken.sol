//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract GLIMPSE is ERC20 {
    constructor() ERC20('GLMS', 'GLIMPSE') {
        _mint(msg.sender, 360_000_000 * 10**18);
    }
}
