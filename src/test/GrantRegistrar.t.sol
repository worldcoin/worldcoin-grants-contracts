// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { PRBTest } from '@prb/test/PRBTest.sol';
import { WorldIDIdentityManagerRouterMock } from 'src/test/mock/WorldIDIdentityManagerRouterMock.sol';
import { TestERC20 } from './mock/TestERC20.sol';
import { GrantRegistrar } from '../GrantRegistrar.sol';
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
}
