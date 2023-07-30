// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {LaunchGrant} from "../LaunchGrant.sol";

/// @title LaunchGrantTest
/// @notice Contains tests for the launch grant claims.
/// @author Worldcoin
contract MonthlyGrantTest is PRBTest {
    uint256 public startTime = 1682319600; // Monday, 24 April 2023 07:00:00
    uint256 public launchDay = 1690182000; // Monday, 24 July 2023 07:00:00
    LaunchGrant internal launchGrant;

    function setUp() public {
        vm.warp(startTime);
        launchGrant = new LaunchGrant();
    }

    /// @notice Tests that the id of first grant is 0.
    function testInitialMonth() public {
        vm.warp(startTime);
        assertEq(launchGrant.getCurrentId(), 0);
    }

    /// @notice Tests the id of launch grant.
    function testInitialLaunch2Weeks() public {
        vm.warp(launchDay);
        assertEq(launchGrant.getCurrentId(), 13);
        vm.warp(launchDay + 2 weeks - 1);
        assertEq(launchGrant.getCurrentId(), 13);
    }

    /// @notice Tests the single weeks after launch.
    function testConsecutiveSpecialWeeks() public {
        uint startWeekly = 1691391600; // Monday, 7 August 2023 07:00:00
        assertEq(startWeekly, launchDay + 2 weeks);
        vm.warp(startWeekly);
        assertEq(launchGrant.getCurrentId(), 14);

        vm.warp(startWeekly + 1 weeks);
        assertEq(launchGrant.getCurrentId(), 15);

        vm.warp(startWeekly + 2 weeks);
        assertEq(launchGrant.getCurrentId(), 16);
    }

    /// @notice Tests switch to biweekly.
    function testBiWeeklySwitch() public {
        uint startBiweekly = 1693206000; // Monday, 28 August 2023 07:00:00
        assertEq(startBiweekly, launchDay + 5 weeks);
        vm.warp(startBiweekly);
        assertEq(launchGrant.getCurrentId(), 17);

        vm.warp(startBiweekly + 2 weeks);
        assertEq(launchGrant.getCurrentId(), 18);

        vm.warp(startBiweekly + 4 weeks);
        assertEq(launchGrant.getCurrentId(), 19);
    }

}
