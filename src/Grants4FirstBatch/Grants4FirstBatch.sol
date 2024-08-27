// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable2Step } from "./Ownable2Step.sol";
import { Ownable } from "./Ownable.sol";

contract Grants4FirstBatch is Ownable2Step {
    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Error that is thrown if the caller is not allowed to call the function
    error OnlyAllowedCaller();

    /// @notice Error that is thrown if the input arrays have different lengths
    error LengthMismatch();

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

    /// @notice Event emitted when the RecurringGrantDrop is set
    event RecurringGrantDropSet(address indexed recurringGrantDrop);

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

    /// @notice Recurring Grant Drop contract
    IRecurringGrantDrop public RECURRING_GRANT_DROP;

    /// @notice addresses that can call the batch function
    mapping(address => bool) public allowedCallers;

    ////////////////////////////////////////////////////////////////
    ///                       CONSTRUCTOR                        ///
    ////////////////////////////////////////////////////////////////

    constructor(
        address _allowanceModuleAddress,
        address _wldToken,
        address _holder,
        address _recurringGrantDrop
    )
        Ownable(msg.sender)
    {
        ALLOWANCE_MODULE = AllowanceModule(_allowanceModuleAddress);
        WLD_TOKEN = _wldToken;
        HOLDER = GnosisSafe(_holder);
        RECURRING_GRANT_DROP = IRecurringGrantDrop(_recurringGrantDrop);
    }

    ////////////////////////////////////////////////////////////////
    ///                        FUNCTIONS                         ///
    ////////////////////////////////////////////////////////////////

    /// @notice Batch setNullifierHash + transfer WLD tokens to multiple addresses
    /// @param _nullifierHashes array of nullifier hashes
    /// @param _recipients array of recipient addresses
    /// @param _amounts array of amounts to transfer
    function batch(
        uint256[] calldata _nullifierHashes,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    )
        external
    {
        if (!(_nullifierHashes.length == _recipients.length && _recipients.length == _amounts.length)) {
            revert LengthMismatch();
        }

        if (!allowedCallers[msg.sender]) {
            revert OnlyAllowedCaller();
        }

        uint256 batchSize = _nullifierHashes.length;
        uint256 successfulExecutions = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            try RECURRING_GRANT_DROP.setNullifierHash(_nullifierHashes[i]) {
                AllowanceModule(ALLOWANCE_MODULE).executeAllowanceTransfer(
                    HOLDER, WLD_TOKEN, payable(_recipients[i]), uint96(_amounts[i])
                );
                successfulExecutions++;
            } catch (bytes memory) { }
        }

        emit BatchProcessed(batchSize, successfulExecutions);
    }

    ////////////////////////////////////////////////////////////////
    ///                    CONFIG FUNCTIONS                     ///
    ////////////////////////////////////////////////////////////////

    function setAllowanceModule(address _allowanceModuleAddress) external onlyOwner {
        ALLOWANCE_MODULE = AllowanceModule(_allowanceModuleAddress);
        emit AllowanceModuleSet(_allowanceModuleAddress);
    }

    function setWldToken(address _wldToken) external onlyOwner {
        WLD_TOKEN = _wldToken;
        emit WldTokenSet(_wldToken);
    }

    function setHolder(address _holder) external onlyOwner {
        HOLDER = GnosisSafe(_holder);
        emit HolderSet(_holder);
    }

    function setRecurringGrantDrop(IRecurringGrantDrop _recurringGrantDrop) external onlyOwner {
        RECURRING_GRANT_DROP = _recurringGrantDrop;
        emit RecurringGrantDropSet(address(_recurringGrantDrop));
    }

    function addCaller(address _caller) external onlyOwner {
        allowedCallers[_caller] = true;
        emit CallerAdded(_caller);
    }

    function removeCaller(address _caller) external onlyOwner {
        delete allowedCallers[_caller];
        emit CallerRemoved(_caller);
    }
}

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        external
        returns (bool success);
}

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IRecurringGrantDrop {
    function setNullifierHash(uint256 nullifierHash) external;
}

interface AllowanceModule {
    function executeAllowanceTransfer(GnosisSafe safe, address token, address payable to, uint96 amount) external;
}
