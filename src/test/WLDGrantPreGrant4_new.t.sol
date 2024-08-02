// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WLDGrant} from "../WLDGrantPreGrant4_new.sol";
import {IGrant} from "../IGrantPreGrant4.sol";

/// @title WLDGrantTest
/// @notice Contains tests for the WLDGrant claims.
/// @author Worldcoin
contract WLDGrantTest is PRBTest {
    WLDGrant internal grant;
    uint256 internal constant grant4LaunchDayTimestampInSeconds = 1722470400; // Thursday, 01 August 2024 00:00:00 GMT

    function setUp() public {
        grant = new WLDGrant();
    }

    function testFuzz_checkValidityReverts(uint256 grantId) public {
      vm.assume(grantId < 21 || grantId > 38);
      vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
      grant.checkValidity(grantId);
    }

    function test_checkValidity_grant38() public {
      vm.warp(grant4LaunchDayTimestampInSeconds - 1 weeks);
      grant.checkValidity(38);
    }

    function test_checkValidity_revertsGreaterThanGrant38() public {
      vm.warp(grant4LaunchDayTimestampInSeconds + 1 weeks);
      vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
      grant.checkValidity(39);
    }

    function testFuzz_checkReservationValidityReverts(uint256 timestamp) public {
      vm.assume(timestamp > grant4LaunchDayTimestampInSeconds);
      vm.expectRevert(abi.encodeWithSelector(IGrant.InvalidGrant.selector));
      grant.checkReservationValidity(timestamp);
    }

    function test_checkReservation_grant37() public {
      vm.warp(grant4LaunchDayTimestampInSeconds - (1 weeks));
      grant.checkReservationValidity(grant4LaunchDayTimestampInSeconds - (4 weeks));
    }

    function test_checkReservation_grant38() public {
      vm.warp(grant4LaunchDayTimestampInSeconds);
      grant.checkReservationValidity(grant4LaunchDayTimestampInSeconds - (1 weeks));
    }
}