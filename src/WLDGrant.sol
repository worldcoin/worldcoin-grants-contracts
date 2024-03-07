// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IGrant} from "./IGrant.sol";

contract WLDGrant is IGrant {
    uint256 internal immutable launchDayTimestampInSeconds = 1690167600; // Monday, 24 July 2023 03:00:00

    function calculateId(uint256 timestamp) external pure returns (uint256) {
        if (timestamp < launchDayTimestampInSeconds) revert InvalidGrant();

        uint256 weeksSinceLaunch = (timestamp - launchDayTimestampInSeconds) / 1 weeks;
        uint256 grantId = 15 + (weeksSinceLaunch - 3) / 2;
        // Grant 29 is a four-week grant.
        if (grantId <= 29) return grantId;
        return grantId - 1;
    }

    function getCurrentId() external view override returns (uint256) {
        return this.calculateId(block.timestamp);
    }

    function getAmount(uint256) external pure override returns (uint256) {
        return 3 * 10 ** 18;
    }

    function checkValidity(uint256 grantId) external view override {
        if (this.getCurrentId() != grantId) revert InvalidGrant();

        if (grantId < 21) revert InvalidGrant();
    }

    function checkReservationValidity(uint256 timestamp) external view override {
        uint256 grantId = this.calculateId(timestamp);

        // No future grants can be claimed.
        if (grantId >= this.getCurrentId()) revert InvalidGrant();

        // Only grants 20 and above can be reserved.
        if (grantId < 21) revert InvalidGrant();

        // Reservations are only valid for 12 months.
        if (block.timestamp > timestamp + 52 weeks) revert InvalidGrant();
    }
}
