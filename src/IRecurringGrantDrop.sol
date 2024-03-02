// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRecurringGrantDrop {
    function claim(
        uint256 grantId, 
        address receiver, 
        uint256 root, 
        uint256 nullifierHash, 
        uint256[8] calldata proof
    ) external;
}