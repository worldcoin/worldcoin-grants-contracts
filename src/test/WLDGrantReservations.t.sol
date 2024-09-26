// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WLDGrantReservations} from "../WLDGrantReservations.sol";
import {IGrantReservations} from "../IGrantReservations.sol";

/// @title WLDGrantReservationsTest
/// @author Worldcoin
contract WLDGrantReservationsTest is PRBTest {
    WLDGrantReservations internal grant;
    uint256 internal constant launchDayTimestampInSeconds = 1690167600; // Monday, 24 July 2023 03:00:00
    uint256 internal constant grant4LaunchDayTimestampInSeconds = 1722470400; // Thursday, 01 August 2024 00:00:00 GMT

    function setUp() public {
        grant = new WLDGrantReservations();
    }

    function test_getAmount_grant13() public {
        assertEq(grant.getAmount(13), 25 * 10 ** 18);
    }

    function test_getAmount_grant14() public {
        assertEq(grant.getAmount(14), 10 * 10 ** 18);
    }

    function test_getAmount_grant15() public {
        assertEq(grant.getAmount(15), 3 * 10 ** 18);
    }

    function test_getAmount_grant30() public {
        assertEq(grant.getAmount(30), 6 * 10 ** 18);
    }

    function test_getAmount_grant38() public {
        assertEq(grant.getAmount(38), 3 * 10 ** 18);
    }

    function test_checkReservationValidity_grant13() public {
      vm.warp(grant4LaunchDayTimestampInSeconds);
      grant.checkReservationValidity(launchDayTimestampInSeconds + 3 days);
    }

    function test_checkReservationValidity_grant38() public {
      vm.warp(grant4LaunchDayTimestampInSeconds + 1 weeks);
      grant.checkReservationValidity(grant4LaunchDayTimestampInSeconds - 1 weeks);
    }

    function test_checkReservationValidity_revertsGreaterThanGrant38() public {
      vm.warp(grant4LaunchDayTimestampInSeconds + 10 weeks);
      vm.expectRevert(abi.encodeWithSelector(IGrantReservations.InvalidGrant.selector));
      grant.checkReservationValidity(grant4LaunchDayTimestampInSeconds + 1 weeks);
    }

    function test_checkReservationValidity_revertsLessThan13() public {
      vm.warp(grant4LaunchDayTimestampInSeconds);
      vm.expectRevert(abi.encodeWithSelector(IGrantReservations.InvalidGrant.selector));
      grant.checkReservationValidity(launchDayTimestampInSeconds - 1 weeks);
    }

    function testFuzz_checkReservationValidityReverts(uint256 timestamp) public {
      vm.assume(timestamp > grant4LaunchDayTimestampInSeconds || timestamp < launchDayTimestampInSeconds);
      vm.expectRevert(abi.encodeWithSelector(IGrantReservations.InvalidGrant.selector));
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
