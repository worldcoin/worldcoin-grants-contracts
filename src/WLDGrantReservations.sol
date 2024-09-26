// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IGrantReservations} from "./IGrantReservations.sol";

/**
 * This is the WLDGrant for grantIds [13;38] post grantId 38
 * 
 * While we no longer support claims in this contract for the given range,
 * we do still accept reservations
 */
contract WLDGrantReservations is IGrantReservations {
    uint256 internal immutable launchDayTimestampInSeconds = 1690167600; // Monday, 24 July 2023 03:00:00

    function calculateId(uint256 timestamp) external pure returns (uint256) {
        if (timestamp < launchDayTimestampInSeconds) revert InvalidGrant();

        uint256 weeksSinceLaunch = (timestamp - launchDayTimestampInSeconds) / 1 weeks;
        // Monday, 24 July 2023 07:00:00 until Monday, 07 August 2023 06:59:59 (2 weeks)
        if (weeksSinceLaunch < 2) return 13;
        // Monday, 07 August 2023 03:00:00 until Monday, 14 August 2023 02:59:59 (1 week)
        if (weeksSinceLaunch < 3) return 14;
        uint256 grantId = 15 + (weeksSinceLaunch - 3) / 2;
        // Grant 29 is a four-week grant.
        if (grantId <= 29) return grantId;
        return grantId - 1;
    }

    function getCurrentId() external view override returns (uint256) {
        return this.calculateId(block.timestamp);
    }

    function getAmount(uint256 grantId) external pure override returns (uint256) {
        if (grantId == 13) return 25 * 10 ** 18;
        if (grantId == 14) return 10 * 10 ** 18;
        if (grantId == 30) return 6 * 10 ** 18;
        return 3 * 10 ** 18;
    }

    function checkReservationValidity(uint256 timestamp) external view override {
        uint256 grantId = this.calculateId(timestamp);

        // No future grants can be claimed.
        if (grantId >= this.getCurrentId()) revert InvalidGrant();

        // Only grant reservations with grantIds in the range [13;38] can be redeemed.
        if (grantId < 13 || grantId > 38) revert InvalidGrant();
    }
}
