// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PRBTest} from "@prb/test/PRBTest.sol";
import {NFC_ID} from "../NFC_ID/NFC_ID.sol";
import {MockAllowanceModule} from "./mock/MockAllowanceModule.sol";
import {TestERC20} from "./mock/TestERC20.sol";

/// @title NFC_IDTest
/// @author Worldcoin
contract NFC_IDTest is PRBTest {
    NFC_ID internal nfcId;
    address internal holder;
    TestERC20 internal token;

    function setUp() public {
        token = new TestERC20();
        holder = address(0x4);
        MockAllowanceModule allowanceModule = new MockAllowanceModule(address(token), holder);
        nfcId = new NFC_ID(address(allowanceModule), address(token), holder);
        nfcId.addCaller(address(this));
        
        vm.startPrank(holder);
        token.approve(address(allowanceModule), type(uint256).max);
        vm.stopPrank();
    }

    function test_claim() public {
        address recipient = address(0x1);
        token.issue(holder, 100);
        assertEq(token.balanceOf(holder), 100);
        assertEq(token.balanceOf(recipient), 0);
        nfcId.claim(0, recipient, 100);
        assertEq(token.balanceOf(holder), 0);
        assertEq(token.balanceOf(recipient), 100);
    }

    function test_claim_reverts_if_nullifier_hash_already_set() public {
        address recipient = address(0x1);
        token.issue(holder, 100);
        assertEq(nfcId.nullifierHashes(0), false);
        nfcId.claim(0, recipient, 100);
        assertEq(token.balanceOf(holder), 0);
        assertEq(token.balanceOf(recipient), 100);
        assertEq(nfcId.nullifierHashes(0), true);
        vm.expectRevert(abi.encodeWithSelector(NFC_ID.InvalidNullifier.selector));
        nfcId.claim(0, recipient, 100);
    }

    function test_claim_reverts_if_caller_not_allowed() public {
        vm.prank(address(0x1));
        vm.expectRevert(abi.encodeWithSelector(NFC_ID.OnlyAllowedCaller.selector));
        nfcId.claim(0, address(0x1), 100);
    }
}
