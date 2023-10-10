// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGrant} from './IGrant.sol';
import {IWorldID} from "world-id-contracts/interfaces/IWorldID.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/// @title RecurringGrantDrop
/// @author Worldcoin
contract RecurringGrantDrop is Ownable2Step{
    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev The WorldID router instance that will be used for managing groups and verifying proofs
    IWorldIDGroups public worldIdRouter;

    /// @dev The World ID group whose participants can claim this airdrop
    uint256 public groupId;

    /// @notice The ERC20 token airdropped
    ERC20 public token;

    /// @notice The address that holds the tokens that are being airdropped
    /// @dev Make sure the holder has approved spending for this contract!
    address public holder;

    /// @notice The grant instance used
    IGrant public grant;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) public nullifierHashes;

    /// @dev Allowed addresses to sign a reservation
    mapping(address => bool) internal allowedSigners;

    /// @dev The previous contract that was used for this airdrop
    RecurringGrantDrop internal immutable PREVIOUS_CONTRACT = RecurringGrantDrop(0xe773335550b63eed23a6e60DCC4709106A1F653c);

    /// @dev Needs to be set to the previous contract's last grant ID
    uint256 internal immutable RELEASE_GRANT_ID = 19;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Error in case the configuration is invalid.
    error InvalidConfiguration();

    /// @notice Error in case the receiver is zero address.
    error InvalidReceiver();

    /// @notice Error in case the receiver is zero address.
    error InvalidTimestamp();

    /// @notice Thrown when passed an invalid caller address
    error InvalidSignerAddress();

    /// @notice Thrown when passed an invalid caller address
    error UnauthorizedSigner();

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @notice Emmitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

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

    /// @notice Emitted when the worldIdRouter is changed
    /// @param worldIdRouter The new worldIdRouter instance
    event WorldIdRouterUpdated(IWorldIDGroups worldIdRouter);

    /// @notice Emitted when the groupId is changed
    /// @param groupId The new groupId
    event GroupIdUpdated(uint256 groupId);

    /// @notice Emitted when the token is changed
    /// @param token The new token
    event TokenUpdated(ERC20 token);

    /// @notice Emitted when the holder is changed
    /// @param holder The new holder
    event HolderUpdated(address holder);

    /// @notice Emitted when the grant is changed
    /// @param grant The new grant instance
    event GrantUpdated(IGrant grant);

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
    ) Ownable(msg.sender) {
        if (address(_worldIdRouter) == address(0)) revert InvalidConfiguration();
        if (address(_token) == address(0)) revert InvalidConfiguration();
        if (address(_holder) == address(0)) revert InvalidConfiguration();
        if (address(_grant) == address(0)) revert InvalidConfiguration();

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
        if (receiver == address(0)) revert InvalidReceiver();

        this.checkNullifier(grantId, receiver, root, nullifierHash, proof);

        grant.checkValidity(grantId);

        worldIdRouter.verifyProof(
            root,
            groupId,
            uint256(keccak256(abi.encodePacked(receiver))) >> 8,
            nullifierHash,
            grantId,
            proof
        );
    }

    /// @notice Claim a reserved grant from the past
    /// @param timestamp The timestamp of the reservation
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
    function claimReserved(uint256 timestamp, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof, bytes calldata signature)
        external
    {
        uint256 grantId = grant.calculateId(timestamp);
        checkClaimReserved(timestamp, receiver, root, nullifierHash, proof, signature);

        nullifierHashes[nullifierHash] = true;

        SafeERC20.safeTransferFrom(token, holder, receiver, grant.getAmount(grantId));

        emit GrantClaimed(grantId, receiver);
    }

    /// @notice Check whether a reservation is valid
    /// @param timestamp The timestamp of the reservation
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof, array of 8 uint256 elements, demonstrating that the claimer has a verified World ID
    /// @param signature The off-chain signature of the reservation.
    function checkClaimReserved(uint256 timestamp, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof, bytes calldata signature)
        public
    {
        uint256 grantId = grant.calculateId(timestamp);

        if (receiver == address(0)) revert InvalidReceiver();
        if (timestamp > block.timestamp) revert InvalidTimestamp();

        this.checkNullifier(grantId, receiver, root, nullifierHash, proof);

        grant.checkReservationValidity(timestamp);

        address signer = ECDSA.recover(keccak256(abi.encode(timestamp, nullifierHash)), signature);
        if (!allowedSigners[signer]) revert UnauthorizedSigner();

        worldIdRouter.verifyProof(
            root,
            groupId,
            uint256(keccak256(abi.encodePacked(receiver))) >> 8,
            nullifierHash,
            grantId,
            proof
        );
    }

    /// @notice Check whether a nullifier has been used before in the previous contract.
    function checkNullifier(uint256 grantId, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) external {
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        // If this is for a grant before the new deployment, check the previous contract.
        if (grantId <= RELEASE_GRANT_ID) {
            try PREVIOUS_CONTRACT.checkClaim(grantId, receiver, root, nullifierHash, proof) {
                // This should not happen since only claiming the current grant can succeed, which is already prohibited by the check above.
            } catch (bytes memory reason) {
                // Check if nullifier has already been used.
                if (bytes4(reason) == RecurringGrantDrop.InvalidNullifier.selector) {
                    revert InvalidNullifier();
                }
                // Any other error is fine.
            }
        }
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

    /// @notice Update the worldIdRouter
    /// @param _worldIdRouter The new worldIdRouter
    function setWorldIdRouter(IWorldIDGroups _worldIdRouter) external onlyOwner {
        if (address(_worldIdRouter) == address(0)) revert InvalidConfiguration();

        worldIdRouter = _worldIdRouter;
        emit WorldIdRouterUpdated(_worldIdRouter);
    }

    /// @notice Update the groupId
    /// @param _groupId The new worldIdRouter
    function setGroupId(uint256 _groupId) external onlyOwner {
        groupId = _groupId;

        emit GroupIdUpdated(_groupId);
    }

    /// @notice Update the token
    /// @param _token The new token
    function setToken(ERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert InvalidConfiguration();
        token = _token;
        
        emit TokenUpdated(_token);
    }

    /// @notice Update the holder
    /// @param _holder The new holder
    function setHolder(address _holder) external onlyOwner {
        if (address(_holder) == address(0)) revert InvalidConfiguration();
        holder = _holder;
        
        emit HolderUpdated(holder);
    }

    /// @notice Update the grant
    /// @param _grant The new grant
    function setGrant(IGrant _grant) external onlyOwner {
        if (address(_grant) == address(0)) revert InvalidConfiguration();

        grant = _grant;
        emit GrantUpdated(_grant);
    }

    /// @notice Prevents the owner from renouncing ownership
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
