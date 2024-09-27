// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGrantReservations {
    /// @notice Error in case the grant is invalid.
    error InvalidGrant();

    /// @notice Error in case the grant configuration is invalid.
    error InvalidConfiguration();

    /// @notice Returns the current grant id.
    function getCurrentId() external view returns (uint256);

    /// @notice Returns the amount of tokens for a grant.
    /// @notice This may contain more complicated logic and is therefore not just a member variable.
    /// @param grantId The grant id to get the amount for.
    function getAmount(uint256 grantId) external view returns (uint256);

    /// @notice Calculates the grant id for a given timestamp.
    /// @param timestamp The timestamp to calculate the grant id for.
    function calculateId(uint256 timestamp) external view returns (uint256);

    /// @notice Checks whether a reservation is valid.
    /// @param timestamp The timestamp to check the reservation for.
    function checkReservationValidity(uint256 timestamp) external view;
}
