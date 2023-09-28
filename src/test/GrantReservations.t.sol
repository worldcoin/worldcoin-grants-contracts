// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {GrantReservations} from "../GrantReservations.sol";
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
    bytes public signature;
    uint256 public nullifierHash;
    uint256 public startTime = 1680307200; // Saturday, 1 April 2023 00:00:00 GMT
    TestERC20 internal token;
    WorldIDIdentityManagerRouterMock internal worldIDIdentityManagerRouterMock;
    GrantReservations internal reservations;
    RecurringGrantDrop internal airdrop;
    MonthlyGrant internal monthlyGrant;

    function setUp() public {
        vm.warp(startTime);
        groupId = 1;
        token = new TestERC20();
        worldIDIdentityManagerRouterMock = new WorldIDIdentityManagerRouterMock();
        monthlyGrant = new MonthlyGrant(4, 2023, 1 ether);

        manager = address(0x1);
        caller = address(0x2);
        user = address(0x3);
        holder = address(0x4);
        nullifierHash = uint256(0x04fcdedce0510a2d6fedf97a40c69822ab24b82e7682df8c0d2c2e8fefe6ebcd);
        signature = hex"548323f19ff04e09e797f7db84152e038b8b0b016053dcf854c94f8735151d7f07778a240587f7b70c04916287493e1fc7ade071ec6a2a0480b4609caf7bc8441c";
        proof = [0, 0, 0, 0, 0, 0, 0, 0];

        airdrop = new RecurringGrantDrop(worldIDIdentityManagerRouterMock, groupId, token, holder, monthlyGrant);
        reservations = new GrantReservations(airdrop);
        reservations.addAllowedSigner(address(0x5a944372A297C5CaFE166525E3C631a06787b4b2));
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
        token.approve(address(reservations), type(uint256).max);
        vm.prank(holder);
        token.approve(address(airdrop), type(uint256).max);
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCanClaimPast(uint256 worldIDRoot) public {
        // Move time to next grant
        vm.warp(startTime + 5 weeks);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        reservations.claim(1680307200, user, worldIDRoot, nullifierHash, proof, signature);

        assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCannotClaimClaimed(uint256 worldIDRoot) public {
        vm.warp(startTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

        vm.warp(startTime + 5 weeks);

        vm.expectRevert(GrantReservations.InvalidNullifier.selector);
        reservations.claim(1680307200, user, worldIDRoot, nullifierHash, proof, signature);
    }

    /// @notice Tests that nullifier hash for the same action cannot be consumed twice
    // function testCannotDoubleClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
    //     vm.warp(startTime);
    //     vm.assume(worldIDRoot != 0 && nullifierHash != 0);

    //     assertEq(token.balanceOf(user), 0);

    //     vm.prank(caller);
    //     airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

    //     assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));

    //     vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
    //     vm.prank(caller);
    //     // claim grant 0
    //     airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

    //     assertEq(token.balanceOf(user), monthlyGrant.getAmount(0));
    // }

    // /// @notice Tests that the user is *not* able to claim old grants if they are not valid anymore.
    // function testCannotClaimPast(uint256 worldIDRoot, uint256 nullifierHash) public {
    //     vm.warp(startTime + 31 days);

    //     vm.assume(worldIDRoot != 0 && nullifierHash != 0);

    //     assertEq(token.balanceOf(user), 0);

    //     vm.expectRevert(IGrant.InvalidGrant.selector);
    //     vm.prank(caller);
    //     // claim grant 0
    //     airdrop.claim(0, user, worldIDRoot, nullifierHash, proof);

    //     assertEq(token.balanceOf(user), 0);
    // }

    // /// @notice Tests that the user is *not* able to claim future grants.
    // function testCannotClaimFuture(uint256 worldIDRoot, uint256 nullifierHash) public {
    //     vm.warp(startTime);

    //     vm.assume(worldIDRoot != 0 && nullifierHash != 0);

    //     assertEq(token.balanceOf(user), 0);

    //     vm.expectRevert();
    //     vm.prank(caller);
    //     // claim grant 1
    //     airdrop.claim(1, user, worldIDRoot, nullifierHash, proof);

    //     assertEq(token.balanceOf(user), 0);
    // }

    // /// @notice Tests that the manager can update the grant
    // function testUpdateGrant() public {
    //     MonthlyGrant grant2 = new MonthlyGrant(5, 2023, 1 ether);
    //     assertEq(address(airdrop.grant()), address(monthlyGrant));

    //     vm.prank(manager);
    //     airdrop.setGrant(grant2);

    //     assertEq(address(airdrop.grant()), address(grant2));
    // }

    // /// @notice Tests that anyone that is not the manager can't update grant
    // function testCannotUpdateGrantIfNotManager(address notManager) public {
    //     MonthlyGrant grant2 = new MonthlyGrant(5, 2023, 1 ether);
    //     vm.assume(notManager != manager && notManager != address(0));
    //     assertEq(address(airdrop.grant()), address(monthlyGrant));

    //     vm.expectRevert();
    //     vm.prank(notManager);
    //     airdrop.setGrant(grant2);

    //     assertEq(address(airdrop.grant()), address(monthlyGrant));
    // }
}
