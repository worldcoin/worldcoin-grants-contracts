// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title Test ERC20
/// @notice Wrapper around solmate's ERC20 that instantiates the TEST token.
/// @author Worldcoin
contract TestERC20 is ERC20("Test Token", "TEST") {
    function issue(address receiver, uint256 amount) public {
        _mint(receiver, amount);
    }
}
