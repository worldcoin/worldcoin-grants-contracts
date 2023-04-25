// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';

contract MonthlyGrant is IGrant {
    uint256 internal immutable MAX_VALIDITY = 12;

    // The first grant is in May 2023
    uint256 internal immutable START_MONTH = 5;
    uint256 internal immutable START_YEAR = 2023;

    /// @notice Returns the current grant id starting from 0 (April 2023).
    function getCurrentId() external view override returns (uint256) {
        (uint256 year, uint256 month) = calculateYearAndMonth();
        return (year - START_YEAR) * 12 + month - START_MONTH;
    }

    /// @notice Returns fixed amount of tokens for now.
    function getAmount(uint256) external pure override returns (uint256) {
        return 10_000_000_000;
    }

    // @notice Anything that is not the current grant is invalid.
    function checkValidity(uint256 grantId) external view override {
        if (this.getCurrentId() != grantId) revert InvalidGrant();
    }

    /// @notice Returns the current year and month based on block.timestamp
    /// @notice Algorithm is taken from https://aa.usno.navy.mil/faq/JD_formula
    /// @return year The current year
    /// @return month The current month
    function calculateYearAndMonth() internal view returns (uint256, uint256) {
        uint256 d = block.timestamp / 86400 + 2440588;
        uint256 L = d + 68569;
        uint256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        uint256 year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * year) / 4 + 31;
        uint256 month = (80 * L) / 2447;
        // Removed day calculation:
        // uint256 day = L - (2447 * month) / 80;
        L = month / 11;
        month = month + 2 - 12 * L;
        year = 100 * (N - 49) + year + L;
        return (year, month);
    }
}
