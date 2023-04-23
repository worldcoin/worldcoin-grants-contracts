// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

/////////////////////////////////////////
/// ONLY USED FOR STAGING.
/////////////////////////////////////////

contract HourlyGrant is IGrant {
    function getCurrentId() external view override returns (uint256) {
        // Grant 0: Saturday, 22 April 2023 00:00:00
        return block.timestamp / 3600 - 467256;
    }

    function getAmount(uint256) external pure override returns (uint256) {
        return 10_000_000_000;
    }

    function checkValidity(uint256 grantId) external view override{
        // All grants are valid.
    }
}
