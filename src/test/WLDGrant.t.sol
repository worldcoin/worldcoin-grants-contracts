// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {WLDGrant} from "../WLDGrant.sol";

/// @title WLDGrantTest
/// @notice Contains tests for the WLDGrant claims.
/// @author Worldcoin
contract WLDGrantTest is PRBTest {
    uint256 public launchDay = 1709683200; // Monday, 24 July 2023 03:00:00
    WLDGrant internal grant;

    function setUp() public {
        grant = new WLDGrant();
    }

    /// @notice Tests switch to biweekly.
    function testFourWeekGrant() public {
        uint256 startTimestamp = 1708916400; // Monday, 26 February 2024 03:00:00
        vm.warp(startTimestamp);
        assertEq(grant.getCurrentId(), 29);
        assertEq(grant.getAmount(grant.getCurrentId()), 3 * 10 ** 18);

        // Grant 29 is a four-week grant.
        vm.warp(startTimestamp + 2 weeks);
        assertEq(grant.getCurrentId(), 29);
        assertEq(grant.getAmount(grant.getCurrentId()), 3 * 10 ** 18);

        // Afterwards it switches back to biweekly.
        // Grant 30 is a 6 WLD grant.
        vm.warp(startTimestamp + 4 weeks);
        assertEq(grant.getCurrentId(), 30);
        assertEq(grant.getAmount(grant.getCurrentId()), 6 * 10 ** 18);

        vm.warp(startTimestamp + 6 weeks);
        assertEq(grant.getCurrentId(), 31);
        assertEq(grant.getAmount(grant.getCurrentId()), 3 * 10 ** 18);
    }
}
