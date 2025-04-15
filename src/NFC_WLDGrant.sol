// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IGrant} from "./IGrant.sol";

contract NFC_WLDGrant is IGrant {
    // @notice Launch day timestamp in seconds.
    uint256 internal constant launchDayTimestampInSeconds = 1690167600; // Monday, 24 July 2023 03:00:00 GMT

    // @notice Grants 4.0 launch day timestamp in seconds.
    uint256 internal constant grant4LaunchDayTimestampInSeconds = 1722470400; // Thursday, 01 August 2024 00:00:00 GMT

    uint256[] public grantAmountsList = [
        3090000000000000000,
        3000000000000000000,
        2605000000000000000,
        2265000000000000000,
        2040000000000000000,
        1840000000000000000,
        1650000000000000000,
        1570000000000000000,
        1490000000000000000,
        1420000000000000000,
        1350000000000000000,
        1280000000000000000,
        1210000000000000000,
        1150000000000000000,
        1100000000000000000,
        1040000000000000000,
        990000000000000000,
        940000000000000000,
        890000000000000000,
        850000000000000000,
        810000000000000000,
        770000000000000000,
        730000000000000000,
        690000000000000000,
        650000000000000000,
        610000000000000000,
        570000000000000000,
        540000000000000000,
        510000000000000000,
        750000000000000000,
        705000000000000000,
        665000000000000000,
        625000000000000000,
        585000000000000000,
        550000000000000000,
        520000000000000000,
        480000000000000000,
        450000000000000000,
        415000000000000000,
        390000000000000000,
        360000000000000000,
        335000000000000000,
        310000000000000000,
        290000000000000000,
        270000000000000000,
        250000000000000000,
        235000000000000000,
        215000000000000000,
        200000000000000000,
        185000000000000000
    ];

    mapping(uint256 => uint256) public grantAmounts;

    constructor() {
        // we use a mapping to store the grant amounts for gas efficiency
        for (uint256 i = 0; i < grantAmountsList.length; i++) {
            grantAmounts[i] = grantAmountsList[i];
        }
    }

    /////////////////////////////////////////////////////////////////
    ///                         Functions                         ///
    /////////////////////////////////////////////////////////////////

    // @notice Returns the amount of tokens for a grant.
    // @param grantId The grant id to get the amount for.
    function getAmount(uint256 grantId) external view override returns (uint256) {
        _checkGrantIdBounds(grantId);
        return grantAmounts[grantId - 39];
    }

    // @notice Checks whether a grant is valid.
    // @param grantId The grant id to check.
    function checkValidity(uint256 grantId) external view override {
        _checkGrantIdBounds(grantId);
        if (block.timestamp < grant4LaunchDayTimestampInSeconds) revert InvalidGrant();
        (uint256 grantOne, uint256 grantTwo) = activeGrants();
        if (grantId != grantOne && grantId != grantTwo) revert InvalidGrant();
    }

    // @notice Returns the active grants after the grants 4.0 launch.
    // @notice For August 2024, both return values are 39.
    // @notice For all other months after that, the first return value is 38 + months since August 2024
    // @notice and the second is 39 + months since August 2024.
    function activeGrants() public view returns (uint256 grantOne, uint256 grantTwo) {
        uint256 monthsSinceAugust2024 = _monthsSinceAugust2024();
        if (monthsSinceAugust2024 == 0) {
            return (39, 39);
        }
        return (38 + monthsSinceAugust2024, 39 + monthsSinceAugust2024);
    }

    ////////////////////////////////////////////////////////////////
    ///                   Internal Functions                     ///
    ////////////////////////////////////////////////////////////////

    // @notice Checks whether a grant id is within the bounds supported by the contract.
    function _checkGrantIdBounds(uint256 grantId) internal pure {
        if (grantId < 39 || grantId > 88) {
            revert InvalidGrant();
        }
    }

    // @notice Calculates the number of months since August 2024.
    // @return The number of months since August 2024.
    function _monthsSinceAugust2024() internal view returns (uint256) {
        (uint256 currentYear, uint256 currentMonth) = _calculateYearAndMonth(block.timestamp);

        if (currentYear == 2024 && currentMonth == 8) {
            return 0;
        }

        return (currentYear - 2024) * 12 + currentMonth - 8;
    }

    /// @notice Returns the current year and month based on timestamp
    /// @notice Algorithm is taken from https://aa.usno.navy.mil/faq/JD_formula
    /// @param timestamp The timestamp to calculate the year and month for
    /// @return year The current year
    /// @return month The current month
    function _calculateYearAndMonth(uint256 timestamp) internal pure returns (uint256, uint256) {
        uint256 d = timestamp / 86400 + 2440588;
        uint256 L = d + 68569;
        uint256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        uint256 year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * year) / 4 + 31;
        uint256 month = (80 * L) / 2447;
        L = month / 11;
        month = month + 2 - 12 * L;
        year = 100 * (N - 49) + year + L;
        return (year, month);
    }
}
