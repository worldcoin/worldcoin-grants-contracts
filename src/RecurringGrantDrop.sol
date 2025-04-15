// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IGrant} from "./IGrant.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {GnosisSafe} from "./IAllowanceModule.sol";
import {AllowanceModule} from "./IAllowanceModule.sol";

/// @title RecurringGrantDrop
/// @author Worldcoin
contract RecurringGrantDrop is Ownable2Step {
    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev The constant used for the grant ID external nullifier hash
    uint256 public constant WORLDCHAIN_NULLIFIER_HASH_CONSTANT =
        0x1E00000000000000000000000000000000000000000000000000000000000000;

    /// @dev The WorldID router instance that will be used for managing groups and verifying proofs
    IWorldIDGroups public worldIdRouter;

    /// @dev The World ID group whose participants can claim this airdrop
    uint256 public groupId;

    /// @notice The ERC20 token airdropped
    ERC20 public token;

    /// @notice The grant instance used
    IGrant public grant;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) public nullifierHashes;

    /// @notice BVI Safe that grants allowances to this contract
    GnosisSafe public holder;

    /// @notice address of the Safe Allowance Module
    AllowanceModule public allowanceModule;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Error in case the configuration is invalid.
    error InvalidConfiguration();

    /// @notice Error in case the receiver is zero address.
    error InvalidReceiver();

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
    event RecurringGrantDropInitialized(
        IWorldIDGroups _worldIdRouter,
        uint256 _groupId,
        ERC20 _token,
        address _holder,
        IGrant _grant,
        address _allowanceModuleAddress

    );

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
        IGrant _grant,
        address _allowanceModuleAddress
    ) Ownable(msg.sender) {
        if (address(_worldIdRouter) == address(0)) revert InvalidConfiguration();
        if (address(_token) == address(0)) revert InvalidConfiguration();
        if (address(_holder) == address(0)) revert InvalidConfiguration();
        if (address(_grant) == address(0)) revert InvalidConfiguration();
        if (address(_allowanceModuleAddress) == address(0)) revert InvalidConfiguration();

        worldIdRouter = _worldIdRouter;
        groupId = _groupId;
        token = _token;
        holder = GnosisSafe(_holder);
        grant = _grant;
        allowanceModule = AllowanceModule(_allowanceModuleAddress);

        emit RecurringGrantDropInitialized(
            worldIdRouter, groupId, token, address(holder), grant, _allowanceModuleAddress
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CLAIM LOGIC                               ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Claim the airdrop
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
    function claim(
        uint256 grantId,
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        checkClaim(grantId, receiver, root, nullifierHash, proof);

        nullifierHashes[nullifierHash] = true;

        allowanceModule.executeAllowanceTransfer(
            holder, address(token), payable(receiver), uint96(grant.getAmount(grantId))
        );

        emit GrantClaimed(grantId, receiver);
    }

    /// @notice Check whether a claim is valid
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    function checkClaim(
        uint256 grantId,
        address receiver,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        if (receiver == address(0)) revert InvalidReceiver();

        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        grant.checkValidity(grantId);

        worldIdRouter.verifyProof(
            root,
            groupId,
            uint256(keccak256(abi.encodePacked(receiver))) >> 8,
            nullifierHash,
            grantId + WORLDCHAIN_NULLIFIER_HASH_CONSTANT,
            proof
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONFIG LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

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
        holder = GnosisSafe(_holder);

        emit HolderUpdated(address(holder));
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
