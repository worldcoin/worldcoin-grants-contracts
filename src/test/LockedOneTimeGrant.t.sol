// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {IWorldIDVerifierV2} from "src/IWorldIDVerifierV2.sol";
import {LockedOneTimeGrant} from "src/LockedOneTimeGrant.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {MockAllowanceModule} from "./mock/MockAllowanceModule.sol";
import {WorldIDVerifierV2Mock} from "./mock/WorldIDVerifierV2Mock.sol";

/// @title LockedOneTimeGrant Tests
/// @author Worldcoin
contract LockedOneTimeGrantTest is PRBTest {
    uint64 internal constant RP_ID = 1_000;
    uint64 internal constant ORB_ISSUER_SCHEMA_ID = 1;
    uint256 internal constant CREDENTIAL_GENESIS_ISSUED_AT_MIN = 1_782_864_000;
    uint96 internal constant INITIAL_AMOUNT = 5 * 10 ** 18;
    uint96 internal constant UPDATED_AMOUNT = 7 * 10 ** 18;
    uint64 internal constant INITIAL_LOCKUP_PERIOD = 94_608_000; // 1095 days
    uint64 internal constant UPDATED_LOCKUP_PERIOD = 31_536_000; // 365 days
    uint256 internal constant CLAIM_TIME = 1_800_000_000;
    uint256 internal constant NULLIFIER_HASH = 111;
    uint256 internal constant SECOND_NULLIFIER_HASH = 222;
    uint256 internal constant NONCE = 333;
    uint64 internal constant EXPIRES_AT_MIN = 2_000_000_000;

    address internal manager;
    address internal caller;
    address internal user;
    address internal secondUser;
    address internal holder;

    uint256 internal action;

    TestERC20 internal token;
    MockAllowanceModule internal allowanceModule;
    WorldIDVerifierV2Mock internal verifier;
    LockedOneTimeGrant internal grantDrop;

    function setUp() public {
        manager = address(0x1);
        caller = address(0x2);
        user = address(0x3);
        secondUser = address(0x4);
        holder = address(0x5);

        token = new TestERC20();
        allowanceModule = new MockAllowanceModule(address(token), holder);
        verifier = new WorldIDVerifierV2Mock(false);
        action = uint256(keccak256(abi.encodePacked("worldcoin-grants-one-time"))) >> 8;

        vm.prank(manager);
        grantDrop = new LockedOneTimeGrant(
            verifier,
            token,
            holder,
            address(allowanceModule),
            RP_ID,
            action,
            ORB_ISSUER_SCHEMA_ID,
            CREDENTIAL_GENESIS_ISSUED_AT_MIN,
            INITIAL_AMOUNT,
            INITIAL_LOCKUP_PERIOD
        );

        token.issue(holder, 100 ether);

        vm.prank(holder);
        token.approve(address(allowanceModule), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////
    ///                         Constructor                      ///
    ////////////////////////////////////////////////////////////////

    function test_constructorStoresConfiguration() public {
        assertEq(address(grantDrop.worldIdVerifier()), address(verifier));
        assertEq(address(grantDrop.token()), address(token));
        assertEq(address(grantDrop.holder()), holder);
        assertEq(address(grantDrop.allowanceModule()), address(allowanceModule));
        assertEq(grantDrop.rpId(), RP_ID);
        assertEq(grantDrop.action(), action);
        assertEq(grantDrop.issuerSchemaId(), ORB_ISSUER_SCHEMA_ID);
        assertEq(grantDrop.credentialGenesisIssuedAtMin(), CREDENTIAL_GENESIS_ISSUED_AT_MIN);
        assertEq(grantDrop.grantAmount(), INITIAL_AMOUNT);
        assertEq(grantDrop.lockupPeriod(), INITIAL_LOCKUP_PERIOD);
        assertEq(grantDrop.owner(), manager);
    }

    function test_constructorRejectsInvalidActionForWorldIdV2() public {
        uint256 invalidAction = action | (uint256(1) << 248);

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        new LockedOneTimeGrant(
            verifier,
            token,
            holder,
            address(allowanceModule),
            RP_ID,
            invalidAction,
            ORB_ISSUER_SCHEMA_ID,
            CREDENTIAL_GENESIS_ISSUED_AT_MIN,
            INITIAL_AMOUNT,
            INITIAL_LOCKUP_PERIOD
        );
    }

    function test_constructorRejectsZeroAmount() public {
        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        new LockedOneTimeGrant(
            verifier,
            token,
            holder,
            address(allowanceModule),
            RP_ID,
            action,
            ORB_ISSUER_SCHEMA_ID,
            CREDENTIAL_GENESIS_ISSUED_AT_MIN,
            0,
            INITIAL_LOCKUP_PERIOD
        );
    }

    ////////////////////////////////////////////////////////////////
    ///                           Claim                          ///
    ////////////////////////////////////////////////////////////////

    function test_claimRegistersGrantWithoutTransferAndForwardsVerifierInputs() public {
        vm.warp(CLAIM_TIME);
        _expectVerifierCall(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN);

        vm.prank(caller);
        grantDrop.claim(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());

        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);
        assertEq(grant.receiver, user);
        assertEq(grant.amount, INITIAL_AMOUNT);
        assertEq(grant.claimedAt, CLAIM_TIME);
        assertEq(grant.unlockAt, CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        assertTrue(!grant.withdrawn);
        assertEq(grantDrop.registeredNullifierHashes(user), NULLIFIER_HASH);
        assertEq(grantDrop.grantBalanceOf(user), INITIAL_AMOUNT);
        assertEq(grantDrop.lockedBalanceOf(user), INITIAL_AMOUNT);
        assertEq(grantDrop.claimableBalanceOf(user), 0);
        assertEq(token.balanceOf(user), 0);
        assertEq(token.balanceOf(holder), 100 ether);
    }

    function test_claimRevertsForZeroReceiver() public {
        vm.expectRevert(LockedOneTimeGrant.InvalidReceiver.selector);
        grantDrop.claim(address(0), NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function test_claimRevertsForZeroNullifier() public {
        vm.expectRevert(LockedOneTimeGrant.InvalidNullifier.selector);
        grantDrop.claim(user, 0, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function test_claimRevertsWhenNullifierAlreadyClaimed() public {
        _claim(user, NULLIFIER_HASH);

        vm.expectRevert(LockedOneTimeGrant.GrantAlreadyClaimed.selector);
        grantDrop.claim(secondUser, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function test_claimRevertsWhenReceiverAlreadyRegistered() public {
        _claim(user, NULLIFIER_HASH);

        vm.expectRevert(LockedOneTimeGrant.ReceiverAlreadyRegistered.selector);
        grantDrop.claim(user, SECOND_NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function test_claimRevertsWhenVerifierRejectsProof() public {
        WorldIDVerifierV2Mock rejectingVerifier = new WorldIDVerifierV2Mock(true);
        LockedOneTimeGrant rejectingGrantDrop = _deployWithVerifier(rejectingVerifier);

        vm.expectRevert(WorldIDVerifierV2Mock.InvalidProof.selector);
        rejectingGrantDrop.claim(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function test_claimSnapshotsAmountAndLockupForEachUser() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.prank(manager);
        grantDrop.setGrantParameters(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);

        vm.warp(CLAIM_TIME + 10 days);
        _claim(secondUser, SECOND_NULLIFIER_HASH);

        LockedOneTimeGrant.Claim memory firstGrant = grantDrop.claimFor(user);
        LockedOneTimeGrant.Claim memory secondGrant = grantDrop.claimFor(secondUser);

        assertEq(firstGrant.amount, INITIAL_AMOUNT);
        assertEq(firstGrant.unlockAt, CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        assertEq(secondGrant.amount, UPDATED_AMOUNT);
        assertEq(secondGrant.unlockAt, CLAIM_TIME + 10 days + UPDATED_LOCKUP_PERIOD);
    }

    ////////////////////////////////////////////////////////////////
    ///                         Withdraw                         ///
    ////////////////////////////////////////////////////////////////

    function test_withdrawCanBeCalledByAnyoneAfterLockup() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                LockedOneTimeGrant.GrantLocked.selector, CLAIM_TIME + INITIAL_LOCKUP_PERIOD
            )
        );
        grantDrop.withdraw(NULLIFIER_HASH);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        vm.prank(caller);
        grantDrop.withdraw(NULLIFIER_HASH);

        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);
        assertTrue(grant.withdrawn);
        assertEq(token.balanceOf(user), INITIAL_AMOUNT);
        assertEq(token.balanceOf(holder), 100 ether - INITIAL_AMOUNT);
        assertEq(grantDrop.grantBalanceOf(user), 0);
        assertEq(grantDrop.lockedBalanceOf(user), 0);
        assertEq(grantDrop.claimableBalanceOf(user), 0);
    }

    function test_claimableBalanceIsVisibleAfterUnlockBeforeWithdraw() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);

        assertEq(grantDrop.grantBalanceOf(user), INITIAL_AMOUNT);
        assertEq(grantDrop.lockedBalanceOf(user), 0);
        assertEq(grantDrop.claimableBalanceOf(user), INITIAL_AMOUNT);
    }

    function test_withdrawRevertsForUnknownNullifier() public {
        vm.expectRevert(LockedOneTimeGrant.GrantNotClaimed.selector);
        grantDrop.withdraw(NULLIFIER_HASH);
    }

    function test_withdrawRevertsAfterGrantWithdrawn() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        grantDrop.withdraw(NULLIFIER_HASH);

        vm.expectRevert(LockedOneTimeGrant.GrantAlreadyWithdrawn.selector);
        grantDrop.withdraw(NULLIFIER_HASH);
    }

    ////////////////////////////////////////////////////////////////
    ///                          Config                          ///
    ////////////////////////////////////////////////////////////////

    function test_ownerCanUpdateFutureGrantParameters() public {
        vm.prank(manager);
        grantDrop.setGrantParameters(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);

        assertEq(grantDrop.grantAmount(), UPDATED_AMOUNT);
        assertEq(grantDrop.lockupPeriod(), UPDATED_LOCKUP_PERIOD);
    }

    function test_nonOwnerCannotUpdateGrantParameters(address notOwner) public {
        vm.assume(notOwner != manager && notOwner != address(0));

        vm.expectRevert();
        vm.prank(notOwner);
        grantDrop.setGrantParameters(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);
    }

    function test_ownerCanUpdateVerifierTokenHolderAllowanceAndEligibilityDate() public {
        WorldIDVerifierV2Mock newVerifier = new WorldIDVerifierV2Mock(false);
        TestERC20 newToken = new TestERC20();
        MockAllowanceModule newAllowanceModule = new MockAllowanceModule(address(newToken), holder);
        address newHolder = address(0x77);
        uint256 newCredentialGenesisIssuedAtMin = CREDENTIAL_GENESIS_ISSUED_AT_MIN + 1 days;

        vm.startPrank(manager);
        grantDrop.setWorldIdVerifier(newVerifier);
        grantDrop.setToken(newToken);
        grantDrop.setHolder(newHolder);
        grantDrop.setAllowanceModule(address(newAllowanceModule));
        grantDrop.setCredentialGenesisIssuedAtMin(newCredentialGenesisIssuedAtMin);
        vm.stopPrank();

        assertEq(address(grantDrop.worldIdVerifier()), address(newVerifier));
        assertEq(address(grantDrop.token()), address(newToken));
        assertEq(address(grantDrop.holder()), newHolder);
        assertEq(address(grantDrop.allowanceModule()), address(newAllowanceModule));
        assertEq(grantDrop.credentialGenesisIssuedAtMin(), newCredentialGenesisIssuedAtMin);
    }

    function test_ownerCannotRenounceOwnership() public {
        vm.expectRevert(LockedOneTimeGrant.CannotRenounceOwnership.selector);
        vm.prank(manager);
        grantDrop.renounceOwnership();
    }

    ////////////////////////////////////////////////////////////////
    ///                          Helpers                         ///
    ////////////////////////////////////////////////////////////////

    function _claim(address receiver, uint256 nullifierHash) internal {
        _expectVerifierCall(receiver, nullifierHash, NONCE, EXPIRES_AT_MIN);
        vm.prank(caller);
        grantDrop.claim(receiver, nullifierHash, NONCE, EXPIRES_AT_MIN, _proof());
    }

    function _expectVerifierCall(
        address receiver,
        uint256 nullifierHash,
        uint256 nonce,
        uint64 expiresAtMin
    ) internal {
        vm.expectCall(
            address(verifier),
            abi.encodeCall(
                IWorldIDVerifierV2.verify,
                (
                    nullifierHash,
                    action,
                    RP_ID,
                    nonce,
                    grantDrop.signalHash(receiver),
                    expiresAtMin,
                    ORB_ISSUER_SCHEMA_ID,
                    CREDENTIAL_GENESIS_ISSUED_AT_MIN,
                    _proof()
                )
            )
        );
    }

    function _deployWithVerifier(WorldIDVerifierV2Mock _verifier)
        internal
        returns (LockedOneTimeGrant)
    {
        vm.prank(manager);
        return new LockedOneTimeGrant(
            _verifier,
            token,
            holder,
            address(allowanceModule),
            RP_ID,
            action,
            ORB_ISSUER_SCHEMA_ID,
            CREDENTIAL_GENESIS_ISSUED_AT_MIN,
            INITIAL_AMOUNT,
            INITIAL_LOCKUP_PERIOD
        );
    }

    function _proof() internal pure returns (uint256[5] memory proof) {
        proof = [uint256(11), uint256(22), uint256(33), uint256(44), uint256(55)];
    }
}
