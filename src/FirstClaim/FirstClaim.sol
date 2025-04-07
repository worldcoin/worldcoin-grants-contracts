// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract FirstClaim is Ownable2Step {
    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Error that is thrown if the caller is not allowed to call the function
    error OnlyAllowedCaller();

    /// @notice Error that is thrown if a proposed configuration address is the zero address
    error ZeroAddress();

    /// @notice Error that is thrown if the grant amount is too large
    error GrantAmountTooLarge();

    /// @notice Error that is thrown if the owner tries to renounce ownership
    error CannotRenounceOwnership();

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

    /// @notice Event emitted when a first claim has been made
    event FirstClaimClaimed(uint256 grantId, address indexed receiver, uint256 amount);

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
    ) Ownable(msg.sender) {
        if (
            _allowanceModuleAddress == address(0) || _wldToken == address(0)
                || _holder == address(0) || _recurringGrantDrop == address(0)
        ) {
            revert ZeroAddress();
        }
        ALLOWANCE_MODULE = AllowanceModule(_allowanceModuleAddress);
        WLD_TOKEN = _wldToken;
        HOLDER = GnosisSafe(_holder);
        RECURRING_GRANT_DROP = IRecurringGrantDrop(_recurringGrantDrop);
    }

    ////////////////////////////////////////////////////////////////
    ///                        FUNCTIONS                         ///
    ////////////////////////////////////////////////////////////////

    /// @notice Claim the first grant
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @param amount The total amount to claim
    function claim(
        uint256 grantId,
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        uint256 amount
    ) external {
      if (!allowedCallers[msg.sender]) {
        revert OnlyAllowedCaller();
      }

      RECURRING_GRANT_DROP.claim(grantId, receiver, root, nullifierHash, proof);
      uint256 currentGrantAmount = RECURRING_GRANT_DROP.grant().getAmount(grantId);
      if (currentGrantAmount >= amount) {
        revert GrantAmountTooLarge();
      }

      ALLOWANCE_MODULE.executeAllowanceTransfer(
        HOLDER,
        WLD_TOKEN,
        payable(receiver),
        uint96(amount - currentGrantAmount)
      );

        emit FirstClaimClaimed(grantId, receiver, amount);
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

    function setRecurringGrantDrop(IRecurringGrantDrop _recurringGrantDrop) external onlyOwner {
        if (address(_recurringGrantDrop) == address(0)) {
            revert ZeroAddress();
        }
        RECURRING_GRANT_DROP = _recurringGrantDrop;
        emit RecurringGrantDropSet(address(_recurringGrantDrop));
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

    /// @notice Prevents the owner from renouncing ownership
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}

// an interface for the RecurringGrantDrop of this commit https://github.com/worldcoin/worldcoin-grants-contracts/commit/68cf64877cb59d5e96b3894a5c79f63a4c0ffa1f
interface IRecurringGrantDrop {
    function claim(
        uint256 grantId,
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external;

    function grant() external view returns (IGrant);
}

interface IGrant {
  function getAmount(uint256 grantId) external view returns (uint256);
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
