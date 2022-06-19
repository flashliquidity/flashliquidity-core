// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IFlashBorrower {
    function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external;
}
