// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

/////////////////////////////////////////
/// ONLY USED FOR STAGING.
/////////////////////////////////////////

contract HourlyGrant is IGrant {
    uint256 internal immutable offset;
    uint256 internal immutable amount;

    constructor(uint256 _offset, uint256 _amount) {
        offset = _offset;
        amount = _amount;
    }

    function getCurrentId() external view override returns (uint256) {
        return (block.timestamp - offset) / 3600;
    }

    function getAmount(uint256) external view override returns (uint256) {
        return amount;
    }

    function checkValidity(uint256 grantId) external view override{
        if (this.getCurrentId() != grantId) revert InvalidGrant();
    }
}
