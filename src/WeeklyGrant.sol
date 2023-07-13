// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

contract WeeklyGrant is IGrant {
    uint256 internal immutable offset;
    uint256 internal immutable amount;

    constructor(uint256 _offset, uint256 _amount) {
        if (block.timestamp < _offset) revert InvalidConfiguration();

        offset = _offset;
        amount = _amount;
    }

    function getCurrentId() external view override returns (uint256) {
        return (block.timestamp - offset) / 7 days;
    }

    function getAmount(uint256) external view override returns (uint256) {
        return amount;
    }

    function checkValidity(uint256 grantId) external view override{
        if (this.getCurrentId() != grantId) revert InvalidGrant();
    }
}
