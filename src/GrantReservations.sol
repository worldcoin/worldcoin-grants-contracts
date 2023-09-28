// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGrant} from './IGrant.sol';
import {RecurringGrantDrop} from './RecurringGrantDrop.sol';
import {IWorldID} from "world-id-contracts/interfaces/IWorldID.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {console} from 'forge-std/Script.sol';

/// @title GrantReservations
/// @author Worldcoin
contract GrantReservations is Ownable2Step{
    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice The RecurringGrantDrop contract
    RecurringGrantDrop public immutable recurringGrantDrop;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev Allowed addresses to sign a reservation
    mapping(address => bool) internal allowedSigners;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Error in case the configuration is invalid.
    error InvalidConfiguration();

    /// @notice Thrown when passed an invalid caller address
    error InvalidReceiver();

    /// @notice Thrown when passed an invalid caller address
    error InvalidSignerAddress();

    /// @notice Thrown when passed an invalid caller address
    error UnauthorizedSigner();

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @notice Thrown when claiming a grant that is not allowed to be claimed through reservations
    error InvalidGrant();

    /// @notice Thrown if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a GrantReservations is initialized
    /// @param _recurringGrantDrop The grant that contains the amounts and validity
    event GrantReservationsInitialized(RecurringGrantDrop _recurringGrantDrop);

    /// @notice Emitted when a grant is successfully claimed
    /// @param receiver The address that received the tokens
    event GrantClaimed(uint256 grantId, address receiver);

    /// @notice Emitted when an allowed signer is added
    /// @param signer The new signer
    event AllowedSignerAdded(address signer);

    /// @notice Emitted when an allowed signer is removed
    /// @param signer The new signer
    event AllowedSignerRemoved(address signer);

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                              ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Deploys a WorldIDAirdrop instance
    /// @param _recurringGrantDrop The grant that contains the amounts and validity
    constructor(
        RecurringGrantDrop _recurringGrantDrop
    ) Ownable(msg.sender) {
        if (address(_recurringGrantDrop) == address(0)) revert InvalidConfiguration();

        recurringGrantDrop = _recurringGrantDrop;

        emit GrantReservationsInitialized(recurringGrantDrop);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CLAIM LOGIC                               ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Claim the airdrop
    /// @param timestamp The timestamp of the reservation
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
    function claim(uint256 timestamp, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof, bytes calldata signature)
        external
    {

        IGrant grant = recurringGrantDrop.grant();
        uint256 grantId = grant.calculateId(timestamp);
        checkClaim(timestamp, receiver, root, nullifierHash, proof, signature);

        nullifierHashes[nullifierHash] = true;

        SafeERC20.safeTransferFrom(recurringGrantDrop.token(), recurringGrantDrop.holder(), receiver, grant.getAmount(grantId));

        emit GrantClaimed(grantId, receiver);
    }

    /// @notice Check whether a claim is valid
    /// @param timestamp The timestamp of the reservation
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    function checkClaim(uint256 timestamp, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof, bytes calldata signature)
        public
    {
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();
        if (receiver == address(0)) revert InvalidReceiver();

        IGrant grant = recurringGrantDrop.grant();
        uint256 grantId = grant.calculateId(timestamp);
        if (grantId == grant.getCurrentId()) revert InvalidGrant();

        // ecrecovery from sigature and check against allowed signers
        address signer = ECDSA.recover(keccak256(abi.encode(timestamp, nullifierHash)), signature);
        if (!allowedSigners[signer]) revert UnauthorizedSigner();

        // Try to call check claim on recurringGrantDrop
        try recurringGrantDrop.checkClaim(grantId, receiver, root, nullifierHash, proof) {
            // This should not happen since only claiming the current grant can succeed, which is already prohibited by the check above.
        } catch (bytes memory reason) {
            // Check if nullifier has already been used.
            if (bytes4(reason) == RecurringGrantDrop.InvalidNullifier.selector) {
                revert InvalidNullifier();
            }
            // Any other error is fine.
        }
        
        recurringGrantDrop.worldIdRouter().verifyProof(
            root,
            recurringGrantDrop.groupId(),
            uint256(keccak256(abi.encodePacked(receiver))) >> 8,
            nullifierHash,
            grantId,
            proof
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONFIG LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Add a caller to the list of allowed callers
    /// @param _signer The address to add
    function addAllowedSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert InvalidSignerAddress();
        allowedSigners[_signer] = true;
        
        emit AllowedSignerAdded(_signer);
    }

    /// @notice Remove a signer to the list of allowed signers
    /// @param _signer The address to remove
    function removeAllowedSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert InvalidSignerAddress();
        allowedSigners[_signer] = false;

        emit AllowedSignerRemoved(_signer);
    }

    /// @notice Prevents the owner from renouncing ownership
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
