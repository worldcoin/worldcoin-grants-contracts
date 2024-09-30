// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// an interface for the AllowanceModule contract deployed at these addresses
// optimism: 0x948BDE4d8670500b0F62cF5c745C82ABe7c81A65
// worldchain: 0xa9bcF56d9FCc0178414EF27a3d893C9469e437B7
interface AllowanceModule {
    function executeAllowanceTransfer(
        GnosisSafe safe,
        address token,
        address payable to,
        uint96 amount
    ) external;
}

interface GnosisSafe {}
