// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IWorldIDVerifierV2} from "src/IWorldIDVerifierV2.sol";

/// @notice Mock for the new World ID verifier interface.
contract WorldIDVerifierV2Mock is IWorldIDVerifierV2 {
    error InvalidProof();

    bool internal immutable shouldRevert;

    constructor(bool _shouldRevert) {
        shouldRevert = _shouldRevert;
    }

    function verify(
        uint256,
        uint256,
        uint64,
        uint256,
        uint256,
        uint64,
        uint64,
        uint256,
        uint256[5] calldata
    ) external view {
        if (shouldRevert) revert InvalidProof();
    }
}
