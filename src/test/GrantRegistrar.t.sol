// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { PRBTest } from '@prb/test/PRBTest.sol';
import { WorldIDIdentityManagerRouterMock } from 'src/test/mock/WorldIDIdentityManagerRouterMock.sol';
import { TestERC20 } from './mock/TestERC20.sol';
import { GrantRegistrar, IWorldIDGroups } from '../GrantRegistrar.sol';
import { WLDGrant } from '../WLDGrant.sol';
import { IGrant } from '../IGrant.sol';

/// @title GrantRegistrar Tests
/// @author Worldcoin
/// @dev These contracts mock the identity manager (never reverts) and tests the GrantRegistrar
contract GrantRegistrarTest is PRBTest {
  event AmountUpdated(uint256 amount);

  address public user;
  uint256 internal groupId;
  uint256[8] internal proof;
  address public manager;
  address public caller;
  uint256 public startTime = 1690167600; // Monday, 24 July 2023 03:00:00
  uint256 public claimTime = 1699239600; // Monday, 23 October 2023 03:00:00
  uint256 public nullifierHash;
  TestERC20 internal token;
  WorldIDIdentityManagerRouterMock internal worldIDIdentityManagerRouterMock;
  GrantRegistrar internal registrar;
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

    proof = [0, 0, 0, 0, 0, 0, 0, 0];
    nullifierHash = uint256(0x04fcdedce0510a2d6fedf97a40c69822ab24b82e7682df8c0d2c2e8fefe6ebcd);

    vm.prank(manager);
    registrar = new GrantRegistrar(
      worldIDIdentityManagerRouterMock,
      groupId,
      nullifierHash,
      3, // nGrantsValidity
      10 // currentGrantId
    );

    ///////////////////////////////////////////////////////////////////
    ///                            LABELS                           ///
    ///////////////////////////////////////////////////////////////////

    vm.label(caller, 'Caller');
    vm.label(manager, 'Manager');
    vm.label(address(registrar), 'GrantRegistrar');
    vm.label(address(worldIDIdentityManagerRouterMock), 'WorldIDIdentityManagerRouterMock');
  }

  /// @notice Tests that the user is able to claim tokens if the World ID proof is valid
  function testCanVerify(uint256 worldIDRoot, uint256 nullifierHash) public {
    vm.warp(claimTime);

    vm.assume(worldIDRoot != 0 && nullifierHash != 0);

    assertFalse(registrar.canClaimGrant(user, 10));

    vm.prank(caller);
    registrar.verify(user, worldIDRoot, nullifierHash, proof);

    assertTrue(registrar.canClaimGrant(user, 10));
    assertTrue(registrar.canClaimGrant(user, 11));
    assertTrue(registrar.canClaimGrant(user, 12));
    assertTrue(registrar.canClaimGrant(user, 13));
    assertFalse(registrar.canClaimGrant(user, 14));
  }

  function testCannotReverifyBeforeExpiry(
    uint256 worldIDRoot,
    uint256 nullifierHash,
    uint256 grantsPassed
  ) public {
    vm.assume(worldIDRoot != 0 && nullifierHash != 0 && grantsPassed != 0 && grantsPassed <= 3);

    vm.warp(claimTime);

    assertFalse(registrar.canClaimGrant(user, 10));

    vm.prank(caller);
    registrar.verify(user, worldIDRoot, nullifierHash, proof);

    assertTrue(registrar.canClaimGrant(user, 10));

    vm.prank(manager);
    registrar.setCurrentGrant(10 + grantsPassed);

    assertTrue(registrar.canClaimGrant(user, 10 + grantsPassed));

    vm.expectRevert(GrantRegistrar.InvalidNullifier.selector);
    vm.prank(caller);
    registrar.verify(user, worldIDRoot, nullifierHash, proof);

    assertTrue(registrar.canClaimGrant(user, 10 + grantsPassed));
    assertFalse(registrar.canClaimGrant(user, 10 + 4));
  }

  /// @notice Tests that nullifier hash for the same action cannot be consumed twice
  function testCannotDoubleVerify(uint256 worldIDRoot, uint256 nullifierHash) public {
    vm.warp(claimTime);
    vm.assume(worldIDRoot != 0 && nullifierHash != 0);

    assertFalse(registrar.canClaimGrant(user, 10));

    vm.prank(caller);
    registrar.verify(user, worldIDRoot, nullifierHash, proof);

    assertTrue(registrar.canClaimGrant(user, 10));

    vm.expectRevert(GrantRegistrar.InvalidNullifier.selector);
    vm.prank(caller);
    registrar.verify(user, worldIDRoot, nullifierHash, proof);
  }

  function testCannotUpdateWorldIdRouterIfNotManager(address notManager) public {
    vm.assume(notManager != manager && notManager != address(0));
    assertEq(address(registrar.worldIdRouter()), address(worldIDIdentityManagerRouterMock));

    vm.expectRevert();
    vm.prank(notManager);
    registrar.setWorldIdRouter(IWorldIDGroups(address(0x1)));

    assertEq(address(registrar.worldIdRouter()), address(worldIDIdentityManagerRouterMock));
  }

  function testCannotUpdateGroupIdIfNotManager(address notManager) public {
    vm.assume(notManager != manager && notManager != address(0));
    assertEq(registrar.groupId(), 1);

    vm.expectRevert();
    vm.prank(notManager);
    registrar.setGroupId(2);

    assertEq(registrar.groupId(), 1);
  }

  function testCannotUpdateCurrentGrantIfNotManager(address notManager) public {
    vm.assume(notManager != manager && notManager != address(0));
    assertEq(registrar.currentGrantId(), 10);

    vm.expectRevert();
    vm.prank(notManager);
    registrar.setCurrentGrant(11);

    assertEq(registrar.currentGrantId(), 10);
  }

  function testCannotReduceCurrentGrant(uint256 newGrant) public {
    vm.assume(newGrant < 10);
    assertEq(registrar.currentGrantId(), 10);

    vm.expectRevert(GrantRegistrar.InvalidConfiguration.selector);
    vm.prank(manager);
    registrar.setCurrentGrant(newGrant);

    assertEq(registrar.currentGrantId(), 10);
  }

  function testCannotUpdateGrantValidityIfNotManager(address notManager) public {
    vm.assume(notManager != manager && notManager != address(0));
    assertEq(registrar.nGrantsValidity(), 3);

    vm.expectRevert();
    vm.prank(notManager);
    registrar.setGrantValidity(10);

    assertEq(registrar.nGrantsValidity(), 3);
  }

  function testCannotReduceGrantValidity(uint256 newGrantValidity) public {
    vm.assume(newGrantValidity < 3);
    assertEq(registrar.nGrantsValidity(), 3);

    vm.expectRevert(GrantRegistrar.InvalidConfiguration.selector);
    vm.prank(manager);
    registrar.setGrantValidity(newGrantValidity);

    assertEq(registrar.nGrantsValidity(), 3);
  }

  function testCannotRenounceOwnership(address caller) public {
    assertEq(registrar.owner(), manager);

    vm.expectRevert();
    vm.prank(caller);
    registrar.renounceOwnership();

    assertEq(registrar.owner(), manager);
  }
}
