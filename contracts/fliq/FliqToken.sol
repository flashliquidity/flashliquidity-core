// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract FliqToken is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor() public ERC20("FlashLiquidity", "FLIQ") {
        _mint(msg.sender, 100000000000000000000000000); // 10 milions
    }
}