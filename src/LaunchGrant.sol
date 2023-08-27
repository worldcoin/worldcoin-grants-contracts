// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

contract LaunchGrant is IGrant {
    uint256 internal immutable launchDayTimestampInSeconds  = 1690167600; // Monday, 24 July 2023 03:00:00

    function getCurrentId() external view override returns (uint256) {
        uint weeksSinceLaunch = (block.timestamp - launchDayTimestampInSeconds) / 1 weeks;
        // Monday, 24 July 2023 07:00:00 until Monday, 07 August 2023 06:59:59 (2 weeks)
        if (weeksSinceLaunch < 2) return 13;
        // Monday, 07 August 2023 07:00:00 until Monday, 14 August 2023 06:59:59 (1 week)
        if (weeksSinceLaunch < 3) return 14;
        return 15 + (weeksSinceLaunch - 3) / 2;
    }

    function getAmount(uint256 grantId) external pure override returns (uint256) {
        if (grantId == 13) return 25 * 10**18;
        if (grantId == 14) return 10 * 10**18;
        if (grantId == 15) return 3  * 10**18;
        if (grantId == 16) return 3  * 10**18;
        return 2 * 10**18;
    }

    function checkValidity(uint256 grantId) external view override{
        if (this.getCurrentId() != grantId) revert InvalidGrant();
    }
}
