// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {FirstClaim} from "../FirstClaim/FirstClaim.sol";
import {MockAllowanceModule} from "./mock/MockAllowanceModule.sol";
import {TestERC20} from "./mock/TestERC20.sol";
import {IGrant} from "../IGrant.sol";
import {IRecurringGrantDrop} from "../FirstClaim/FirstClaim.sol";

/// @title FirstClaimTest
/// @author Worldcoin
contract FirstClaimTest is PRBTest {
    FirstClaim internal firstClaim;
    address internal holder;
    TestERC20 internal token;
    MockRecurringGrantDrop internal recurringGrantDrop;
    MockGrant internal grant;

    function setUp() public {
        token = new TestERC20();
        holder = address(0x4);
        grant = new MockGrant();
        recurringGrantDrop = new MockRecurringGrantDrop(grant);
        MockAllowanceModule allowanceModule = new MockAllowanceModule(address(token), holder);
        firstClaim = new FirstClaim(
            address(allowanceModule),
            address(token),
            holder,
            address(recurringGrantDrop),
            30000000000000000000
        );
        firstClaim.addCaller(address(this));

        vm.startPrank(holder);
        token.approve(address(allowanceModule), type(uint256).max);
        vm.stopPrank();
    }

    function test_claim() public {
        address recipient = address(0x1);
        uint256 grantId = 1;
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof = [uint256(1), 2, 3, 4, 5, 6, 7, 8];
        uint256 amount = 200;
        uint256 currentGrantAmount = 100;

        // Set initial grant amount
        grant.setAmount(currentGrantAmount);

        // Issue tokens to holder for the allowance module transfer
        token.issue(holder, amount - currentGrantAmount);
        // Issue tokens to holder for the recurring grant drop transfer
        token.issue(holder, currentGrantAmount);
        
        assertEq(token.balanceOf(holder), amount);
        assertEq(token.balanceOf(recipient), 0);

        // Mock the recurring grant drop transfer
        vm.prank(holder);
        token.transfer(recipient, currentGrantAmount);

        firstClaim.claim(grantId, recipient, root, nullifierHash, proof, amount);

        // Verify both the token transfer and that RGD claim was called
        assertEq(token.balanceOf(holder), 0);
        assertEq(token.balanceOf(recipient), amount);
        assertTrue(recurringGrantDrop.claimCalled());
        assertEq(recurringGrantDrop.lastClaimGrantId(), grantId);
        assertEq(recurringGrantDrop.lastClaimRecipient(), recipient);
        assertEq(recurringGrantDrop.lastClaimRoot(), root);
        assertEq(recurringGrantDrop.lastClaimNullifierHash(), nullifierHash);
    }

    function test_claim_reverts_if_caller_not_allowed() public {
        address recipient = address(0x1);
        uint256 grantId = 1;
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof = [uint256(1), 2, 3, 4, 5, 6, 7, 8];
        uint256 amount = 200;

        vm.prank(address(0x1));
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.OnlyAllowedCaller.selector));
        firstClaim.claim(grantId, recipient, root, nullifierHash, proof, amount);
    }

    function test_claim_reverts_if_max_claim_amount_exceeded() public {
        address recipient = address(0x1);
        uint256 grantId = 1;
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof = [uint256(1), 2, 3, 4, 5, 6, 7, 8];
        uint256 amount = 40000000000000000000;

        vm.expectRevert(abi.encodeWithSelector(FirstClaim.MaxClaimAmountExceeded.selector));
        firstClaim.claim(grantId, recipient, root, nullifierHash, proof, amount);
    }

    function test_claim_reverts_if_grant_amount_too_large() public {
        address recipient = address(0x1);
        uint256 grantId = 1;
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof = [uint256(1), 2, 3, 4, 5, 6, 7, 8];
        uint256 amount = 100;

        // Set mock grant amount to be GREATER than requested amount to trigger revert
        grant.setAmount(amount + 1);

        vm.expectRevert(abi.encodeWithSelector(FirstClaim.GrantAmountTooLarge.selector));
        firstClaim.claim(grantId, recipient, root, nullifierHash, proof, amount);
    }

    function test_setAllowanceModule() public {
        address newModule = address(0x123);
        firstClaim.setAllowanceModule(newModule);
        assertEq(address(firstClaim.allowanceModule()), newModule);
    }

    function test_setAllowanceModule_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.setAllowanceModule(address(0));
    }

    function test_setWldToken() public {
        address newToken = address(0x123);
        firstClaim.setWldToken(newToken);
        assertEq(firstClaim.token(), newToken);
    }

    function test_setWldToken_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.setWldToken(address(0));
    }

    function test_setHolder() public {
        address newHolder = address(0x123);
        firstClaim.setHolder(newHolder);
        assertEq(address(firstClaim.holder()), newHolder);
    }

    function test_setHolder_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.setHolder(address(0));
    }

    function test_setRecurringGrantDrop() public {
        MockRecurringGrantDrop newDrop = new MockRecurringGrantDrop(grant);
        firstClaim.setRecurringGrantDrop(newDrop);
        assertEq(address(firstClaim.recurringGrantDrop()), address(newDrop));
    }

    function test_setRecurringGrantDrop_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.setRecurringGrantDrop(IRecurringGrantDrop(address(0)));
    }

    function test_addCaller() public {
        address newCaller = address(0x123);
        assertEq(firstClaim.allowedCallers(newCaller), false);
        firstClaim.addCaller(newCaller);
        assertEq(firstClaim.allowedCallers(newCaller), true);
    }

    function test_addCaller_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.addCaller(address(0));
    }

    function test_removeCaller() public {
        address caller = address(0x123);
        firstClaim.addCaller(caller);
        assertEq(firstClaim.allowedCallers(caller), true);
        firstClaim.removeCaller(caller);
        assertEq(firstClaim.allowedCallers(caller), false);
    }

    function test_removeCaller_reverts_if_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.ZeroAddress.selector));
        firstClaim.removeCaller(address(0));
    }

    function test_cannot_renounce_ownership() public {
        vm.expectRevert(abi.encodeWithSelector(FirstClaim.CannotRenounceOwnership.selector));
        firstClaim.renounceOwnership();
    }
}

contract MockGrant is IGrant {
    uint256 private amount;

    function setAmount(uint256 _amount) external {
        amount = _amount;
    }

    function getAmount(uint256) external view returns (uint256) {
        return amount;
    }

    function checkValidity(uint256 grantId) external view override {}
}

contract MockRecurringGrantDrop is IRecurringGrantDrop {
    IGrant public immutable grant;

    bool public claimCalled;
    uint256 public lastClaimGrantId;
    address public lastClaimRecipient;
    uint256 public lastClaimRoot;
    uint256 public lastClaimNullifierHash;
    uint256[8] public lastClaimProof;

    constructor(IGrant _grant) {
        grant = _grant;
    }

    function claim(
        uint256 grantId,
        address recipient,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        claimCalled = true;
        lastClaimGrantId = grantId;
        lastClaimRecipient = recipient;
        lastClaimRoot = root;
        lastClaimNullifierHash = nullifierHash;
        lastClaimProof = proof;
    }
}
