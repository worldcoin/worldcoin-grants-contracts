// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {WLDGrant} from "../WLDGrant.sol";
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
    uint256 public startTime = 1690167600; // Monday, 24 July 2023 03:00:00
    uint256 public claimTime = 1699239600; // Monday, 23 October 2023 03:00:00
    uint256 public reservationNullifierHash;
    bytes public signature;
    TestERC20 internal token;
    WorldIDIdentityManagerRouterMock internal worldIDIdentityManagerRouterMock;
    RecurringGrantDrop internal airdrop;
    IGrant internal grant;

    function setUp() public {
        vm.warp(startTime);
        groupId = 1;
        token = new TestERC20();
        worldIDIdentityManagerRouterMock = new WorldIDIdentityManagerRouterMock();
        grant = new WLDGrant();

        manager = address(0x1);
        caller = address(0x2);
        user = address(0x3);
        holder = address(0x4);

        proof = [0, 0, 0, 0, 0, 0, 0, 0];

        vm.prank(manager);
        airdrop =
            new RecurringGrantDrop(worldIDIdentityManagerRouterMock, groupId, token, holder, grant);
        vm.prank(manager);
        airdrop.addAllowedReservationSigner(address(0x5a944372A297C5CaFE166525E3C631a06787b4b2));
        reservationNullifierHash =
            uint256(0x04fcdedce0510a2d6fedf97a40c69822ab24b82e7682df8c0d2c2e8fefe6ebcd);
        signature =
            hex"a7e4f7718dc83001950f51f478bd2c2029e464af4f37439f44555829bedeb3d9721cdb007b05ae399b028abae39171c475462c6c50a8e10c3994ac028be7be9e1b";

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
        token.issue(holder, 100 ether);

        // Approve spending from the airdrop contract
        vm.prank(holder);
        token.approve(address(airdrop), type(uint256).max);
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCanClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(21));
    }

    /// @notice Tests that nullifier hash for the same action cannot be consumed twice
    function testCannotDoubleClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(claimTime);
        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(0));

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        vm.prank(caller);

        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(0));
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCanClaimReservation(uint256 worldIDRoot) public {
        vm.warp(claimTime + 2 weeks);

        assertEq(grant.getCurrentId(), 22);
        assertEq(grant.calculateId(claimTime), 21);

        vm.assume(worldIDRoot != 0 && reservationNullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        airdrop.claimReserved(
            claimTime, user, worldIDRoot, reservationNullifierHash, proof, signature
        );

        assertEq(token.balanceOf(user), grant.getAmount(21));
    }

    /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
    function testCannotClaimClaimed(uint256 worldIDRoot) public {
        vm.warp(claimTime);

        vm.assume(worldIDRoot != 0 && reservationNullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(21, user, worldIDRoot, reservationNullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(21));

        vm.warp(claimTime + 2 weeks);

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        airdrop.claimReserved(
            claimTime, user, worldIDRoot, reservationNullifierHash, proof, signature
        );
    }

    /// @notice Tests that the user is *not* able to claim old grants if they are not valid anymore.
    function testCannotClaimPast(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(claimTime + 14 days);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);

        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the user is *not* able to claim future grants.
    function testCannotClaimFuture(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert();
        vm.prank(caller);

        airdrop.claim(22, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the manager can update the grant
    function testUpdateGrant() public {
        WLDGrant grant2 = new WLDGrant();
        assertEq(address(airdrop.grant()), address(grant));

        vm.prank(manager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(grant2));
    }

    /// @notice Tests that anyone that is not the manager can't update grant
    function testCannotUpdateGrantIfNotManager(address notManager) public {
        WLDGrant grant2 = new WLDGrant();
        vm.assume(notManager != manager && notManager != address(0));
        assertEq(address(airdrop.grant()), address(grant));

        vm.expectRevert();
        vm.prank(notManager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(grant));
    }
}
