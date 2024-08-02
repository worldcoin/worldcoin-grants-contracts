// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDropLegacy.sol";
import {LaunchGrantLegacy} from "../LaunchGrantLegacy.sol";

/// @title LaunchGrantTest
/// @notice Contains tests for the launch grant claims.
/// @author Worldcoin
contract MonthlyGrantTest is PRBTest {
    uint256 public launchDay = 1690167600; // Monday, 24 July 2023 03:00:00
    LaunchGrantLegacy internal launchGrant;

    function setUp() public {
        launchGrant = new LaunchGrantLegacy();
    }

    /// @notice Tests the id of launch grant.
    function testInitialLaunch2Weeks() public {
        vm.warp(launchDay);
        assertEq(launchGrant.getCurrentId(), 13);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 25 * 10 ** 18);
        vm.warp(launchDay + 2 weeks - 1);
        assertEq(launchGrant.getCurrentId(), 13);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 25 * 10 ** 18);
    }

    /// @notice Tests the single weeks after launch.
    function testConsecutiveSpecialWeeks() public {
        uint256 startWeekly = 1691377200; // Monday, 7 August 2023 03:00:00
        assertEq(startWeekly, launchDay + 2 weeks);
        vm.warp(startWeekly);
        assertEq(launchGrant.getCurrentId(), 14);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 10 * 10 ** 18);
    }

    /// @notice Tests switch to biweekly.
    function testBiWeeklySwitch() public {
        uint256 startBiweekly = 1691982000; // Monday, 14 August 2023 03:00:00
        assertEq(startBiweekly, launchDay + 3 weeks);
        vm.warp(startBiweekly);
        assertEq(launchGrant.getCurrentId(), 15);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 3 * 10 ** 18);

        vm.warp(startBiweekly + 2 weeks);
        assertEq(launchGrant.getCurrentId(), 16);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 3 * 10 ** 18);

        vm.warp(startBiweekly + 4 weeks);
        assertEq(launchGrant.getCurrentId(), 17);
        assertEq(launchGrant.getAmount(launchGrant.getCurrentId()), 3 * 10 ** 18);
    }
}
