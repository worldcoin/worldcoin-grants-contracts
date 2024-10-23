// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract NFCID_Batch is Ownable2Step {
    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Error that is thrown if the caller is not allowed to call the function
    error OnlyAllowedCaller();

    /// @notice Error that is thrown if the input arrays have different lengths
    error LengthMismatch();

    /// @notice Error that is thrown if a proposed configuration address is the zero address
    error ZeroAddress();

    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Event emitted when a caller is added
    event CallerAdded(address indexed caller);

    /// @notice Event emitted when a caller is removed
    event CallerRemoved(address indexed caller);

    /// @notice Event emitted when the AllowanceModule is set
    event AllowanceModuleSet(address indexed allowanceModule);

    /// @notice Event emitted when the WLD token is set
    event WldTokenSet(address indexed wldToken);

    /// @notice Event emitted when the Holder is set
    event HolderSet(address indexed holder);

    /// @notice Event emitted when a batch has been processed
    event BatchProcessed(uint256 batchSize, uint256 successfulExecutions);

    ////////////////////////////////////////////////////////////////
    ///                      CONFIG STORAGE                      ///
    ////////////////////////////////////////////////////////////////

    /// @notice address of the Safe Allowance Module
    AllowanceModule public ALLOWANCE_MODULE;

    /// @notice Worldcoin token address
    address public WLD_TOKEN;

    /// @notice BVI Safe that grants allowances to this contract
    GnosisSafe public HOLDER;

    /// @notice addresses that can call the batch function
    mapping(address => bool) public allowedCallers;

    /// @notice nullifier hashes that have been set
    mapping(uint256 => bool) public nullifierHashes;

    ////////////////////////////////////////////////////////////////
    ///                       CONSTRUCTOR                        ///
    ////////////////////////////////////////////////////////////////

    constructor(
        address _allowanceModuleAddress,
        address _wldToken,
        address _holder
    ) Ownable(msg.sender) {
        if (
            _allowanceModuleAddress == address(0) || _wldToken == address(0)
                || _holder == address(0)
        ) {
            revert ZeroAddress();
        }
        ALLOWANCE_MODULE = AllowanceModule(_allowanceModuleAddress);
        WLD_TOKEN = _wldToken;
        HOLDER = GnosisSafe(_holder);
    }

    ////////////////////////////////////////////////////////////////
    ///                        FUNCTIONS                         ///
    ////////////////////////////////////////////////////////////////

    /// @notice Batch transfer WLD tokens to multiple addresses
    /// @param _nullifierHashes array of nullifier hashes
    /// @param _recipients array of recipient addresses
    /// @param _amounts array of amounts to transfer
    function batch(
        uint256[] calldata _nullifierHashes,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external {
        if (
            !(_nullifierHashes.length == _recipients.length && _recipients.length == _amounts.length)
        ) {
            revert LengthMismatch();
        }

        if (!allowedCallers[msg.sender]) {
            revert OnlyAllowedCaller();
        }

        uint256 batchSize = _nullifierHashes.length;
        uint256 successfulExecutions = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            if(!nullifierHashes[_nullifierHashes[i]]) {
                nullifierHashes[_nullifierHashes[i]] = true;
                AllowanceModule(ALLOWANCE_MODULE).executeAllowanceTransfer(
                    HOLDER, WLD_TOKEN, payable(_recipients[i]), uint96(_amounts[i])
                );
                successfulExecutions++;
            }
        }

        emit BatchProcessed(batchSize, successfulExecutions);
    }

    ////////////////////////////////////////////////////////////////
    ///                    CONFIG FUNCTIONS                     ///
    ////////////////////////////////////////////////////////////////

    function setAllowanceModule(address _allowanceModuleAddress) external onlyOwner {
        if (_allowanceModuleAddress == address(0)) {
            revert ZeroAddress();
        }
        ALLOWANCE_MODULE = AllowanceModule(_allowanceModuleAddress);
        emit AllowanceModuleSet(_allowanceModuleAddress);
    }

    function setWldToken(address _wldToken) external onlyOwner {
        if (_wldToken == address(0)) {
            revert ZeroAddress();
        }
        WLD_TOKEN = _wldToken;
        emit WldTokenSet(_wldToken);
    }

    function setHolder(address _holder) external onlyOwner {
        if (_holder == address(0)) {
            revert ZeroAddress();
        }
        HOLDER = GnosisSafe(_holder);
        emit HolderSet(_holder);
    }

    function addCaller(address _caller) external onlyOwner {
        if (_caller == address(0)) {
            revert ZeroAddress();
        }
        allowedCallers[_caller] = true;
        emit CallerAdded(_caller);
    }

    function removeCaller(address _caller) external onlyOwner {
        if (_caller == address(0)) {
            revert ZeroAddress();
        }
        delete allowedCallers[_caller];
        emit CallerRemoved(_caller);
    }
}

interface GnosisSafe {}

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
