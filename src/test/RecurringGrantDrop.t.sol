// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {WorldIDIdentityManagerRouterMock} from "src/test/mock/WorldIDIdentityManagerRouterMock.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {RecurringGrantDrop} from "../RecurringGrantDrop.sol";
import {WLDGrant} from "../WLDGrant.sol";
import {IGrant} from "../IGrant.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MockAllowanceModule} from "./mock/MockAllowanceModule.sol";

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
    uint256 public preGrant4_claimTime = 1699239600; // Monday, 23 October 2023 03:00:00
    uint256 public grant4_grant39_claimTime = 1722470400; // Thursday, 01 August 2024 00:00:00
    uint256 public grant4_grant39_2ndMonth_claimTime = grant4_grant39_claimTime + 35 days;
    TestERC20 internal token;
    WorldIDIdentityManagerRouterMock internal worldIDIdentityManagerRouterMock;
    RecurringGrantDrop internal airdrop;
    RecurringGrantDrop internal airdropHarness;
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

        MockAllowanceModule allowanceModule = new MockAllowanceModule(address(token), holder);

        proof = [0, 0, 0, 0, 0, 0, 0, 0];

        vm.prank(manager);
        airdrop = new RecurringGrantDrop(
            worldIDIdentityManagerRouterMock,
            groupId,
            token,
            holder,
            grant,
            address(allowanceModule)
        );
        vm.prank(manager);

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

        vm.prank(holder);
        token.approve(address(allowanceModule), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////
    ///                       Claim tests                        ///
    ////////////////////////////////////////////////////////////////

    /// @notice Tests that the user is not able to claim grants with ids below 39
    function test_cannotClaimBelow39_21(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(preGrant4_claimTime);
        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        vm.prank(caller);
        vm.expectRevert(IGrant.InvalidGrant.selector);
        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);
    }

    /// @notice Tests that the user is not able to claim grants with ids below 39
    function test_cannotClaimBelow39_38(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(grant4_grant39_claimTime - 1 weeks);
        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        vm.prank(caller);
        vm.expectRevert(IGrant.InvalidGrant.selector);
        airdrop.claim(38, user, worldIDRoot, nullifierHash, proof);
    }

    /// @notice Tests that the user is able to claim grant 39 if the World ID proof is valid
    function test_CanClaim39(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(grant4_grant39_claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(39, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(39));
    }

    /// @notice Tests that the user is able to claim grant 39 in its 2nd month if the World ID proof is valid
    function test_CanClaim39_2ndMonth(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(grant4_grant39_2ndMonth_claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(39, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(39));
    }

    /// @notice Tests that nullifier hash for the same action cannot be consumed twice
    function test_CannotDoubleClaim(uint256 worldIDRoot, uint256 nullifierHash) public {
        uint256 grantId = 39;
        vm.warp(grant4_grant39_claimTime);
        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(grantId));

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        vm.prank(caller);

        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(grantId));
    }

    /// @notice Tests that the user cannot claim an already claimed grant
    function test_CannotClaimAlreadyClaimedGrant_39(uint256 worldIDRoot, uint256 nullifierHash)
        public
    {
        uint256 grantId = 39;
        vm.warp(grant4_grant39_claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(grantId));

        vm.warp(grant4_grant39_claimTime + 1 weeks);

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);
    }

    /// @notice Tests that the user cannot claim an already claimed grant
    function test_CannotClaimAlreadyClaimedGrant_40(uint256 worldIDRoot, uint256 nullifierHash)
        public
    {
        uint256 grantId = 40;
        vm.warp(grant4_grant39_2ndMonth_claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.prank(caller);
        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), grant.getAmount(grantId));

        vm.warp(grant4_grant39_2ndMonth_claimTime + 1 weeks);

        vm.expectRevert(RecurringGrantDrop.InvalidNullifier.selector);
        airdrop.claim(grantId, user, worldIDRoot, nullifierHash, proof);
    }

    /// @notice Tests that the user is *not* able to claim old grants if they are not valid anymore.
    function test_CannotClaimPastGrant_21(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(preGrant4_claimTime + 14 days);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);

        airdrop.claim(21, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the user is *not* able to claim old grants if they are not valid anymore.
    function test_CannotClaimPastGrant_39(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(grant4_grant39_2ndMonth_claimTime + 60 days);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);

        airdrop.claim(39, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the user is *not* able to claim future grants.
    function test_CannotClaimFuture_22(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(preGrant4_claimTime);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert();
        vm.prank(caller);

        airdrop.claim(22, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    /// @notice Tests that the user is *not* able to claim future grants.
    function test_CannotClaimFuture_55(uint256 worldIDRoot, uint256 nullifierHash) public {
        vm.warp(grant4_grant39_2ndMonth_claimTime + 4 weeks);

        vm.assume(worldIDRoot != 0 && nullifierHash != 0);

        assertEq(token.balanceOf(user), 0);

        vm.expectRevert(IGrant.InvalidGrant.selector);
        vm.prank(caller);

        airdrop.claim(55, user, worldIDRoot, nullifierHash, proof);

        assertEq(token.balanceOf(user), 0);
    }

    ////////////////////////////////////////////////////////////////
    ///                       Config tests                       ///
    ////////////////////////////////////////////////////////////////

    /// @notice Tests that the manager can update the grant
    function test_UpdateGrant() public {
        WLDGrant grant2 = new WLDGrant();
        assertEq(address(airdrop.grant()), address(grant));

        vm.prank(manager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(grant2));
    }

    /// @notice Tests that anyone that is not the manager can't update grant
    function test_CannotUpdateGrantIfNotManager(address notManager) public {
        WLDGrant grant2 = new WLDGrant();
        vm.assume(notManager != manager && notManager != address(0));
        assertEq(address(airdrop.grant()), address(grant));

        vm.expectRevert();
        vm.prank(notManager);
        airdrop.setGrant(grant2);

        assertEq(address(airdrop.grant()), address(grant));
    }
}
