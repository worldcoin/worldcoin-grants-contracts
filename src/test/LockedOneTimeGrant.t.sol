// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDVerifierV2} from "src/IWorldIDVerifierV2.sol";
import {IWIP101, LockedOneTimeGrant} from "src/LockedOneTimeGrant.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {MockAllowanceModule} from "./mock/MockAllowanceModule.sol";
import {WorldIDVerifierV2Mock} from "./mock/WorldIDVerifierV2Mock.sol";

/// @title LockedOneTimeGrant Tests
/// @author Worldcoin
contract LockedOneTimeGrantTest is PRBTest {
    event LockedOneTimeGrantInitialized(
        IWorldIDVerifierV2 indexed worldIdVerifier,
        ERC20 indexed token,
        address indexed holder,
        address allowanceModule,
        uint64 rpId,
        uint256 action,
        uint64 issuerSchemaId,
        uint256 credentialGenesisIssuedAtMin,
        uint96 grantAmount,
        uint64 lockupPeriod
    );
    event GrantClaimed(
        uint256 indexed nullifierHash, address indexed receiver, uint96 amount, uint64 unlockAt
    );
    event GrantWithdrawn(uint256 indexed nullifierHash, address indexed receiver, uint96 amount);
    event WorldIdVerifierUpdated(IWorldIDVerifierV2 indexed worldIdVerifier);
    event HolderUpdated(address indexed holder);
    event AllowanceModuleUpdated(address indexed allowanceModule);
    event GrantParametersUpdated(uint96 grantAmount, uint64 lockupPeriod);
    event CredentialGenesisIssuedAtMinUpdated(uint256 credentialGenesisIssuedAtMin);
    event StoppedUpdated(bool stopped);
    event Transfer(address indexed from, address indexed to, uint256 value);

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

    struct DeployConfig {
        IWorldIDVerifierV2 worldIdVerifier;
        ERC20 token;
        address holder;
        address allowanceModule;
        uint64 rpId;
        uint256 action;
        uint64 issuerSchemaId;
        uint256 credentialGenesisIssuedAtMin;
        uint96 grantAmount;
        uint64 lockupPeriod;
    }

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
        assertTrue(!grantDrop.stopped());
        assertEq(grantDrop.owner(), manager);
    }

    function test_constructorEmitsInitializedEvent() public {
        vm.expectEmit(true, true, true, true);
        emit LockedOneTimeGrantInitialized(
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

        vm.prank(manager);
        new LockedOneTimeGrant(
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
    }

    function test_constructorRejectsInvalidConfiguration() public {
        DeployConfig memory config = _validDeployConfig();
        config.worldIdVerifier = IWorldIDVerifierV2(address(0));
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.token = ERC20(address(0));
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.holder = address(0);
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.allowanceModule = address(0);
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.rpId = 0;
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.action = 0;
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.action = action | (uint256(1) << 248);
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.issuerSchemaId = 0;
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.credentialGenesisIssuedAtMin = 0;
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.grantAmount = 0;
        _expectDeployConfigRevert(config);

        config = _validDeployConfig();
        config.lockupPeriod = 0;
        _expectDeployConfigRevert(config);
    }

    ////////////////////////////////////////////////////////////////
    ///                           Claim                          ///
    ////////////////////////////////////////////////////////////////

    function test_claimRegistersGrantAndPullsFundsIntoContract() public {
        vm.warp(CLAIM_TIME);
        _expectVerifierCall(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN);
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(holder, address(grantDrop), INITIAL_AMOUNT);
        vm.expectEmit(true, true, false, true, address(grantDrop));
        emit GrantClaimed(
            NULLIFIER_HASH, user, INITIAL_AMOUNT, uint64(CLAIM_TIME + INITIAL_LOCKUP_PERIOD)
        );

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
        assertEq(token.balanceOf(address(grantDrop)), INITIAL_AMOUNT);
        assertEq(token.balanceOf(holder), 100 ether - INITIAL_AMOUNT);
    }

    function test_balancesReturnZeroForUnregisteredReceiver() public {
        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);

        assertEq(grant.receiver, address(0));
        assertEq(grantDrop.grantBalanceOf(user), 0);
        assertEq(grantDrop.lockedBalanceOf(user), 0);
        assertEq(grantDrop.claimableBalanceOf(user), 0);
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

    function test_claimRevertsWhenAllowanceIsRevoked() public {
        vm.prank(holder);
        token.approve(address(allowanceModule), 0);

        _expectVerifierCall(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN);
        vm.expectRevert();
        vm.prank(caller);
        grantDrop.claim(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());

        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);
        assertEq(grant.receiver, address(0));
        assertEq(grantDrop.registeredNullifierHashes(user), 0);
        assertEq(token.balanceOf(address(grantDrop)), 0);
    }

    function test_claimRevertsWhenHolderBalanceIsInsufficient() public {
        uint256 holderBalance = token.balanceOf(holder);

        vm.prank(holder);
        token.transfer(address(0x99), holderBalance);

        _expectVerifierCall(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN);
        vm.expectRevert();
        vm.prank(caller);
        grantDrop.claim(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());

        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);
        assertEq(grant.receiver, address(0));
        assertEq(grantDrop.registeredNullifierHashes(user), 0);
        assertEq(token.balanceOf(address(grantDrop)), 0);
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

    function test_claimUsesUpdatedCredentialGenesisIssuedAtMin() public {
        vm.prank(manager);
        grantDrop.setCredentialGenesisIssuedAtMin(CREDENTIAL_GENESIS_ISSUED_AT_MIN + 1 days);

        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);
    }

    function test_claimRevertsWhenStopped() public {
        vm.prank(manager);
        grantDrop.setStopped(true);

        vm.expectRevert(LockedOneTimeGrant.GrantStopped.selector);
        grantDrop.claim(user, NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());
    }

    ////////////////////////////////////////////////////////////////
    ///                         WIP-101                          ///
    ////////////////////////////////////////////////////////////////

    function test_supportsWip101Interfaces() public {
        assertEq(type(IWIP101).interfaceId, IWIP101.verifyRpRequest.selector);
        assertTrue(grantDrop.supportsInterface(type(IERC165).interfaceId));
        assertTrue(grantDrop.supportsInterface(type(IWIP101).interfaceId));
        assertTrue(!grantDrop.supportsInterface(0xffffffff));
    }

    function test_verifyRpRequestAuthorizesGrantAction() public {
        vm.warp(CLAIM_TIME);

        bytes4 magicValue = grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp), uint64(block.timestamp + 1 hours), action, ""
        );

        assertEq(magicValue, grantDrop.WIP101_MAGIC_VALUE());
    }

    function test_verifyRpRequestRejectsUnsupportedRequests() public {
        vm.warp(CLAIM_TIME);

        _expectRpInvalidRequest(grantDrop.WIP101_INVALID_ACTION());
        grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp), uint64(block.timestamp + 1 hours), action + 1, ""
        );

        _expectRpInvalidRequest(grantDrop.WIP101_UNSUPPORTED_AUX_DATA());
        grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp), uint64(block.timestamp + 1 hours), action, hex"01"
        );
    }

    function test_verifyRpRequestRejectsInvalidMetadata() public {
        vm.warp(CLAIM_TIME);

        _expectRpInvalidRequest(grantDrop.WIP101_INVALID_VERSION());
        grantDrop.verifyRpRequest(
            2, NONCE, uint64(block.timestamp), uint64(block.timestamp + 1 hours), action, ""
        );

        _expectRpInvalidRequest(grantDrop.WIP101_INVALID_TIMESTAMP());
        grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp + 1), uint64(block.timestamp + 1 hours), action, ""
        );

        _expectRpInvalidRequest(grantDrop.WIP101_INVALID_TIMESTAMP());
        grantDrop.verifyRpRequest(
            1,
            NONCE,
            uint64(block.timestamp + 2 hours),
            uint64(block.timestamp + 1 hours),
            action,
            ""
        );

        _expectRpInvalidRequest(grantDrop.WIP101_INVALID_TIMESTAMP());
        grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp - 1 hours), uint64(block.timestamp), action, ""
        );
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
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(address(grantDrop), user, INITIAL_AMOUNT);
        vm.expectEmit(true, true, false, true, address(grantDrop));
        emit GrantWithdrawn(NULLIFIER_HASH, user, INITIAL_AMOUNT);

        vm.prank(caller);
        grantDrop.withdraw(NULLIFIER_HASH);

        LockedOneTimeGrant.Claim memory grant = grantDrop.claimFor(user);
        assertTrue(grant.withdrawn);
        assertEq(token.balanceOf(user), INITIAL_AMOUNT);
        assertEq(token.balanceOf(holder), 100 ether - INITIAL_AMOUNT);
        assertEq(token.balanceOf(address(grantDrop)), 0);
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

    function test_withdrawUsesAlreadyFundedClaimAfterHolderAndModuleUpdates() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        address newHolder = address(0x77);
        MockAllowanceModule newAllowanceModule = new MockAllowanceModule(address(token), newHolder);

        token.issue(newHolder, 100 ether);
        vm.prank(newHolder);
        token.approve(address(newAllowanceModule), type(uint256).max);

        vm.startPrank(manager);
        grantDrop.setHolder(newHolder);
        grantDrop.setAllowanceModule(address(newAllowanceModule));
        vm.stopPrank();

        _claim(secondUser, SECOND_NULLIFIER_HASH);

        assertEq(token.balanceOf(address(grantDrop)), INITIAL_AMOUNT * 2);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        grantDrop.withdraw(NULLIFIER_HASH);

        assertEq(token.balanceOf(user), INITIAL_AMOUNT);
        assertEq(token.balanceOf(address(grantDrop)), INITIAL_AMOUNT);
    }

    function test_withdrawRevertsAfterGrantWithdrawn() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        grantDrop.withdraw(NULLIFIER_HASH);

        vm.expectRevert(LockedOneTimeGrant.GrantAlreadyWithdrawn.selector);
        grantDrop.withdraw(NULLIFIER_HASH);
    }

    function test_withdrawStillWorksWhenStopped() public {
        vm.warp(CLAIM_TIME);
        _claim(user, NULLIFIER_HASH);

        vm.prank(manager);
        grantDrop.setStopped(true);

        vm.expectRevert(LockedOneTimeGrant.GrantStopped.selector);
        grantDrop.claim(secondUser, SECOND_NULLIFIER_HASH, NONCE, EXPIRES_AT_MIN, _proof());

        vm.expectRevert(
            abi.encodeWithSelector(IWIP101.RpInvalidRequest.selector, grantDrop.WIP101_STOPPED())
        );
        grantDrop.verifyRpRequest(
            1, NONCE, uint64(block.timestamp), uint64(block.timestamp + 1 hours), action, ""
        );

        vm.warp(CLAIM_TIME + INITIAL_LOCKUP_PERIOD);
        grantDrop.withdraw(NULLIFIER_HASH);

        assertEq(token.balanceOf(user), INITIAL_AMOUNT);
    }

    ////////////////////////////////////////////////////////////////
    ///                          Config                          ///
    ////////////////////////////////////////////////////////////////

    function test_ownerCanUpdateFutureGrantParameters() public {
        vm.expectEmit(false, false, false, true, address(grantDrop));
        emit GrantParametersUpdated(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);

        vm.prank(manager);
        grantDrop.setGrantParameters(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);

        assertEq(grantDrop.grantAmount(), UPDATED_AMOUNT);
        assertEq(grantDrop.lockupPeriod(), UPDATED_LOCKUP_PERIOD);
    }

    function test_nonOwnerCannotUpdateConfiguration(address notOwner) public {
        vm.assume(notOwner != manager && notOwner != address(0));

        WorldIDVerifierV2Mock newVerifier = new WorldIDVerifierV2Mock(false);
        address newHolder = address(0x77);
        MockAllowanceModule newAllowanceModule = new MockAllowanceModule(address(token), newHolder);

        vm.startPrank(notOwner);
        vm.expectRevert();
        grantDrop.setWorldIdVerifier(newVerifier);
        vm.expectRevert();
        grantDrop.setHolder(newHolder);
        vm.expectRevert();
        grantDrop.setAllowanceModule(address(newAllowanceModule));
        vm.expectRevert();
        grantDrop.setGrantParameters(UPDATED_AMOUNT, UPDATED_LOCKUP_PERIOD);
        vm.expectRevert();
        grantDrop.setCredentialGenesisIssuedAtMin(CREDENTIAL_GENESIS_ISSUED_AT_MIN + 1 days);
        vm.expectRevert();
        grantDrop.setStopped(true);
        vm.stopPrank();
    }

    function test_ownerCanUpdateVerifierHolderAllowanceAndEligibilityDate() public {
        WorldIDVerifierV2Mock newVerifier = new WorldIDVerifierV2Mock(false);
        address newHolder = address(0x77);
        MockAllowanceModule newAllowanceModule = new MockAllowanceModule(address(token), newHolder);
        uint256 newCredentialGenesisIssuedAtMin = CREDENTIAL_GENESIS_ISSUED_AT_MIN + 1 days;

        vm.startPrank(manager);
        vm.expectEmit(true, false, false, true, address(grantDrop));
        emit WorldIdVerifierUpdated(newVerifier);
        grantDrop.setWorldIdVerifier(newVerifier);

        vm.expectEmit(true, false, false, true, address(grantDrop));
        emit HolderUpdated(newHolder);
        grantDrop.setHolder(newHolder);

        vm.expectEmit(true, false, false, true, address(grantDrop));
        emit AllowanceModuleUpdated(address(newAllowanceModule));
        grantDrop.setAllowanceModule(address(newAllowanceModule));

        vm.expectEmit(false, false, false, true, address(grantDrop));
        emit CredentialGenesisIssuedAtMinUpdated(newCredentialGenesisIssuedAtMin);
        grantDrop.setCredentialGenesisIssuedAtMin(newCredentialGenesisIssuedAtMin);
        vm.stopPrank();

        assertEq(address(grantDrop.worldIdVerifier()), address(newVerifier));
        assertEq(address(grantDrop.token()), address(token));
        assertEq(address(grantDrop.holder()), newHolder);
        assertEq(address(grantDrop.allowanceModule()), address(newAllowanceModule));
        assertEq(grantDrop.credentialGenesisIssuedAtMin(), newCredentialGenesisIssuedAtMin);
    }

    function test_settersRejectInvalidConfiguration() public {
        vm.startPrank(manager);
        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setWorldIdVerifier(IWorldIDVerifierV2(address(0)));

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setHolder(address(0));

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setAllowanceModule(address(0));

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setGrantParameters(0, UPDATED_LOCKUP_PERIOD);

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setGrantParameters(UPDATED_AMOUNT, 0);

        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        grantDrop.setCredentialGenesisIssuedAtMin(0);
        vm.stopPrank();
    }

    function test_ownerCanStopAndResume() public {
        vm.startPrank(manager);
        vm.expectEmit(false, false, false, true, address(grantDrop));
        emit StoppedUpdated(true);
        grantDrop.setStopped(true);
        assertTrue(grantDrop.stopped());

        vm.expectEmit(false, false, false, true, address(grantDrop));
        emit StoppedUpdated(false);
        grantDrop.setStopped(false);
        assertTrue(!grantDrop.stopped());
        vm.stopPrank();
    }

    function test_ownerCanLowerCredentialGenesisIssuedAtMin() public {
        uint256 loweredCredentialGenesisIssuedAtMin = CREDENTIAL_GENESIS_ISSUED_AT_MIN - 1;

        vm.expectEmit(false, false, false, true, address(grantDrop));
        emit CredentialGenesisIssuedAtMinUpdated(loweredCredentialGenesisIssuedAtMin);

        vm.prank(manager);
        grantDrop.setCredentialGenesisIssuedAtMin(loweredCredentialGenesisIssuedAtMin);

        assertEq(grantDrop.credentialGenesisIssuedAtMin(), loweredCredentialGenesisIssuedAtMin);
    }

    function test_ownershipTransferUsesTwoStepFlow() public {
        address newOwner = address(0x88);

        vm.prank(manager);
        grantDrop.transferOwnership(newOwner);

        assertEq(grantDrop.owner(), manager);
        assertEq(grantDrop.pendingOwner(), newOwner);

        vm.prank(newOwner);
        grantDrop.acceptOwnership();

        assertEq(grantDrop.owner(), newOwner);
        assertEq(grantDrop.pendingOwner(), address(0));
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
                    grantDrop.credentialGenesisIssuedAtMin(),
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

    function _validDeployConfig() internal view returns (DeployConfig memory config) {
        config = DeployConfig({
            worldIdVerifier: verifier,
            token: token,
            holder: holder,
            allowanceModule: address(allowanceModule),
            rpId: RP_ID,
            action: action,
            issuerSchemaId: ORB_ISSUER_SCHEMA_ID,
            credentialGenesisIssuedAtMin: CREDENTIAL_GENESIS_ISSUED_AT_MIN,
            grantAmount: INITIAL_AMOUNT,
            lockupPeriod: INITIAL_LOCKUP_PERIOD
        });
    }

    function _expectDeployConfigRevert(DeployConfig memory config) internal {
        vm.expectRevert(LockedOneTimeGrant.InvalidConfiguration.selector);
        vm.prank(manager);
        new LockedOneTimeGrant(
            config.worldIdVerifier,
            config.token,
            config.holder,
            config.allowanceModule,
            config.rpId,
            config.action,
            config.issuerSchemaId,
            config.credentialGenesisIssuedAtMin,
            config.grantAmount,
            config.lockupPeriod
        );
    }

    function _expectRpInvalidRequest(uint256 code) internal {
        vm.expectRevert(abi.encodeWithSelector(IWIP101.RpInvalidRequest.selector, code));
    }

    function _proof() internal pure returns (uint256[5] memory proof) {
        proof = [uint256(11), uint256(22), uint256(33), uint256(44), uint256(55)];
    }
}
