// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGrant} from './IGrant.sol';
import {IWorldID} from "world-id-contracts/interfaces/IWorldID.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {ByteHasher} from "world-id-contracts/libraries/ByteHasher.sol";

/// @title RecurringGrantDrop
/// @author Worldcoin
contract RecurringGrantDrop {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev The WorldID router instance that will be used for managing groups and verifying proofs
    IWorldIDGroups internal immutable worldIdRouter;

    /// @dev The World ID group whose participants can claim this airdrop
    uint256 internal immutable groupId;

    /// @notice The ERC20 token airdropped
    ERC20 public immutable token;

    /// @notice The address that holds the tokens that are being airdropped
    /// @dev Make sure the holder has approved spending for this contract!
    address public immutable holder;

    /// @notice The address that manages this airdrop
    address public immutable manager = msg.sender;

    /// @notice The     grant instance used
    IGrant public grant;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev Allowed addresses to call `claim`
    mapping(address => bool) internal allowedCallers;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when restricted functions are called by not allowed addresses
    error Unauthorized();

    /// @notice Thrown when passed an invalid caller address
    error InvalidCallerAddress();

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a grant is successfully claimed
    /// @param _worldIdRouter The WorldID router that will manage groups and verify proofs
    /// @param _groupId The group ID of the World ID
    /// @param _token The ERC20 token that will be airdropped
    /// @param _holder The address holding the tokens that will be airdropped
    /// @param _grant The grant that contains the amounts and validity
    event RecurringGrantDropInitialized(IWorldIDGroups _worldIdRouter, uint256 _groupId, ERC20 _token, address _holder, IGrant _grant);

    /// @notice Emitted when a grant is successfully claimed
    /// @param receiver The address that received the tokens
    event GrantClaimed(uint256 grantId, address receiver);

    /// @notice Emitted when the grant is changed
    /// @param grant The new grant instance
    event GrantUpdated(IGrant grant);

    /// @notice Emitted when an allowed caller is added
    /// @param caller The new caller
    event AllowedCallerAdded(address caller);

    /// @notice Emitted when an allowed caller is removed
    /// @param caller The new caller
    event AllowedCallerRemoved(address caller);

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                              ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Deploys a WorldIDAirdrop instance
    /// @param _worldIdRouter The WorldID router that will manage groups and verify proofs
    /// @param _groupId The group ID of the World ID
    /// @param _token The ERC20 token that will be airdropped
    /// @param _holder The address holding the tokens that will be airdropped
    /// @param _grant The grant that contains the amounts and validity
    constructor(
        IWorldIDGroups _worldIdRouter,
        uint256 _groupId,
        ERC20 _token,
        address _holder,
        IGrant _grant
    ) {
        worldIdRouter = _worldIdRouter;
        groupId = _groupId;
        token = _token;
        holder = _holder;
        grant = _grant;

        emit RecurringGrantDropInitialized(worldIdRouter, groupId, token, holder, grant);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CLAIM LOGIC                               ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Claim the airdrop
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
    function claim(uint256 grantId, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)
        external
    {
        if (!allowedCallers[msg.sender]) revert Unauthorized();

        checkClaim(grantId, receiver, root, nullifierHash, proof);

        nullifierHashes[nullifierHash] = true;

        SafeERC20.safeTransferFrom(token, holder, receiver, grant.getAmount(grantId));

        emit GrantClaimed(grantId, receiver);
    }

    /// @notice Check whether a claim is valid
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    function checkClaim(uint256 grantId, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)
        public
    {
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();
        
        grant.checkValidity(grantId);

        worldIdRouter.verifyProof(
            groupId,
            root,
            abi.encodePacked(receiver).hashToField(),
            nullifierHash,
            grantId,
            proof
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONFIG LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Add a caller to the list of allowed callers
    /// @param _caller The address to add
    function addAllowedCaller(address _caller) external {
        if (msg.sender != manager) revert Unauthorized();
        if (_caller == address(0)) revert InvalidCallerAddress();
        allowedCallers[_caller] = true;
        
        emit AllowedCallerAdded(_caller);
    }

    /// @notice Remove a caller to the list of allowed callers
    /// @param _caller The address to remove
    function removeAllowedCaller(address _caller) external {
        if (msg.sender != manager) revert Unauthorized();
        if (_caller == address(0)) revert InvalidCallerAddress();
        allowedCallers[_caller] = false;

        emit AllowedCallerRemoved(_caller);
    }

    /// @notice Update the grant
    /// @param _grant The new grant
    function setGrant(IGrant _grant) external {
        if (msg.sender != manager) revert Unauthorized();
        grant = _grant;
        emit GrantUpdated(_grant);
    }
}
