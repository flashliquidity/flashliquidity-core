// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IFlashBorrower.sol';

interface IFlashLender {
    event LogFlashLoan(address indexed borrower, address indexed receiver, address indexed rewardsToken, uint256 amount, uint256 fee);
    
    function flashLoan(IFlashBorrower borrower, address receiver, uint256 amount, bytes calldata data) external;
}
