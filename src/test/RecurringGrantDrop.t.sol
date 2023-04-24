// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {MonthlyGrant} from "../MonthlyGrant.sol";
import {IGrant} from "../IGrant.sol";

/// @title RecurringGrantDrop Tests
/// @author Worldcoin
/// @dev These contracts mock the identity manager (never reverts) and tests the airdrop
/// functionality for a single airdrop.
contract RecurringGrantDropTest is PRBTest {
    event AmountUpdated(uint256 amount);

    address public user;
    uint256 internal groupId;
    uint256[8] internal proof;
    address public manager;
    address public caller;
    address public holder;
    uint256 public startTime = 1682899200;
    TestERC20 internal token;
    WorldIDIdentityManagerRouterMock internal worldIDIdentityManagerRouterMock;
    RecurringGrantDrop internal airdrop;
    MonthlyGrant internal monthlyGrant;

    function setUp() public {
        groupId = 1;
        token = new TestERC20();
        worldIDIdentityManagerRouterMock = new WorldIDIdentityManagerRouterMock();
        monthlyGrant = new MonthlyGrant();

        manager = address(0x1);
        caller = address(0x2);
        user = address(0x3);
        holder = address(0x4);

        proof = [0, 0, 0, 0, 0, 0, 0, 0];

        vm.prank(manager);
        airdrop = new RecurringGrantDrop(worldIDIdentityManagerRouterMock, groupId, token, holder, monthlyGrant);
        vm.prank(manager);
        airdrop.addAllowedCaller(caller);

        ///////////////////////////////////////////////////////////////////
        ///                            LABELS                           ///
        ///////////////////////////////////////////////////////////////////

        vm.label(user, "Holder");
        vm.label(manager, "Manager");
        vm.label(caller, "Caller");
        vm.label(holder, "Holder");
        vm.label(address(token), "Token");
        vm.label(address(worldIDIdentityManagerRouterMock), "WorldIDIdentityManagerRouterMock");
        vm.label(address(airdrop), "RecurringGrantDrop");

        // Issue some tokens to the user address, to be airdropped from the contract
        token.issue(holder, 10 ether);

        // Approve spending from the airdrop contract
        vm.prank(holder);
        token.approve(address(airdrop), type(uint256).max);
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCanClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(startTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));
    }

    /// @notice Tests that the user is able to claim old grants if they are still valid.
    function testCanClaimOld(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(startTime + 31 days);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));
    }

    /// @notice Tests that the user is *not* able to claim old grants if they are not valid anymore.
    function testCannotClaimTooOld(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(startTime + 400 days);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that nullifier hash for the same action cannot be consumed twice
    function testCannotDoubleClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(startTime);
        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));
    }

    /// @notice Tests that the user is *not* able to claim future grants.
    function testCannotClaimFuture(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(startTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);
        airdrop.claim(1, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the manager can update the grant
    function testUpdateGrant() public {
        MonthlyGrant grant2 = new MonthlyGrant();
        assertEq(address(airdrop.grant()), address(monthlyGrant));

        vm.prank(manager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(grant2));
    }

    /// @notice Tests that anyone that is not the manager can't update grant
    function testCannotUpdateGrantIfNotManager(address notManager) public {
        MonthlyGrant grant2 = new MonthlyGrant();
        vm.assume(notManager != manager && notManager != address(0));
        assertEq(address(airdrop.grant()), address(monthlyGrant));

        vm.expectRevert(RecurringGrantDrop.Unauthorized.selector);
        vm.prank(notManager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(monthlyGrant));
    }
}
