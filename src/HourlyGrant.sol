// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

/////////////////////////////////////////
/// ONLY USED FOR STAGING.
/////////////////////////////////////////

contract HourlyGrant is IGrant {
    uint256 public immutable offset;
    uint256 public immutable amount;

    constructor(uint256 _offset, uint256 _amount) {
        offset = _offset;
        amount = _amount;
    }

    function getCurrentId() external view override returns (uint256) {
        return block.timestamp / 3600 - offset;
    }

    function getAmount(uint256) external view override returns (uint256) {
        return amount;
    }

    function checkValidity(uint256 grantId) external view override{
        // All grants are valid.
    }
}
