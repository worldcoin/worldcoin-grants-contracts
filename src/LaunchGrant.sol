// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

contract LaunchGrant is IGrant {
    uint256 internal immutable launchDayTimestampInSeconds  = 1690167600; // Monday, 24 July 2023 03:00:00

    function calculateId(uint256 timestamp) external pure returns (uint256) {
        if (timestamp < launchDayTimestampInSeconds) revert InvalidGrant();

        uint weeksSinceLaunch = (timestamp - launchDayTimestampInSeconds) / 1 weeks;
        // Monday, 24 July 2023 07:00:00 until Monday, 07 August 2023 06:59:59 (2 weeks)
        if (weeksSinceLaunch < 2) return 13;
        // Monday, 07 August 2023 03:00:00 until Monday, 14 August 2023 02:59:59 (1 week)
        if (weeksSinceLaunch < 3) return 14;
        return 15 + (weeksSinceLaunch - 3) / 2;
    }

    function getCurrentId() external view override returns (uint256) {
        return this.calculateId(block.timestamp);
    }

    function getAmount(uint256 grantId) external pure override returns (uint256) {
        if (grantId == 13) return 25 * 10**18;
        if (grantId == 14) return 10 * 10**18;
        return 3 * 10**18;
    }

    function checkValidity(uint256 grantId) external view override{
        if (this.getCurrentId() != grantId) revert InvalidGrant();

        if (grantId >= 20) revert InvalidGrant();
    }

    function checkReservationValidity(uint256 timestamp) external view override {
        uint256 grantId = this.calculateId(timestamp);

        // No future grants can be claimed.
        if (grantId >= this.getCurrentId()) revert InvalidGrant();

        // Only grants 13 until 19 can be redeemed through this contract.
        if (grantId < 13 || grantId >= 20) revert InvalidGrant();

        // Reservations are only valid for 12 months.
        if (block.timestamp > timestamp + 52 weeks) revert InvalidGrant();
    }
}
