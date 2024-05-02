// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import { IWorldIDGroups } from 'world-id-contracts/interfaces/IWorldIDGroups.sol';
import { Ownable2Step } from 'openzeppelin-contracts/contracts/access/Ownable2Step.sol';

/// @title GrantRegistrar
/// @author Worldcoin
contract GrantRegistrar is Ownable2Step {
  ///////////////////////////////////////////////////////////////////////////////
  ///                              CONFIG STORAGE                            ///
  //////////////////////////////////////////////////////////////////////////////

  /// @dev The WorldID router instance that will be used for managing groups and verifying proofs
  IWorldIDGroups public worldIdRouter;

  /// @dev The World ID group whose participants can verify with this contract.
  uint256 public groupId;

  /// @dev The World ID nullifier hash that will be used to verify proofs.
  uint256 immutable externalNullifierHash;

  /// @dev The maximum grant ID that can be claimed without re-verifying.
  uint256 public maxGrantId;

  /// @dev The current grant ID.
  uint256 public currentGrantId;

  /// @dev Whether a nullifier hash has been used already, and if so, the grant ID it was used for. Used to prevent double-signaling.
  mapping(uint256 => uint256) public nullifierHashes;

  /// @dev The last grant this address will be able to claim before re-registering
  mapping(address => uint256) public expiryGrantIds;

  ///////////////////////////////////////////////////////////////////////////////
  ///                                  ERRORS                                ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Error in case the configuration is invalid.
  error InvalidConfiguration();

  /// @notice Thrown when attempting to reuse a nullifier
  error InvalidNullifier();

  /// @notice Emmitted in revert if the owner attempts to resign ownership.
  error CannotRenounceOwnership();

  ///////////////////////////////////////////////////////////////////////////////
  ///                                  EVENTS                                ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Emitted when the contract is initialized
  /// @param worldIdRouter The WorldID router that will manage groups and verify proofs
  /// @param groupId The group ID of the World ID
  /// @param externalNullifierHash The nullifier hash that will be used to verify proofs
  /// @param maxGrantId The maximum grant ID that can be claimed without re-verifying
  /// @param currentGrantId The current grant ID
  event GrantRegistrarInitialized(
    IWorldIDGroups worldIdRouter,
    uint256 groupId,
    uint256 externalNullifierHash,
    uint256 maxGrantId,
    uint256 currentGrantId
  );

  /// @notice Emitted when a user registers their wallet to receive grants
  /// @param receiver The address that will receive the grants
  /// @param expiryGrantId The last grant this address will be able to claim before re-registering
  event WalletRegistered(address receiver, uint256 expiryGrantId);

  /// @notice Emitted when the worldIdRouter is changed
  /// @param worldIdRouter The new worldIdRouter instance
  event WorldIdRouterUpdated(IWorldIDGroups worldIdRouter);

  /// @notice Emitted when the groupId is changed
  /// @param groupId The new groupId
  event GroupIdUpdated(uint256 groupId);

  /// @notice Emitted when the currentGrandId is changed
  /// @param currentGrantId The new grantId
  event CurrentGrantIdUpdated(uint256 currentGrantId);

  /// @notice Emitted when the maxGrantId is changed
  /// @param maxGrantId The new maxGrantId
  event MaxGrantIdUpdated(uint256 maxGrantId);

  ///////////////////////////////////////////////////////////////////////////////
  ///                               CONSTRUCTOR                              ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Deploys a WorldIDAirdrop instance
  /// @param _worldIdRouter The WorldID router that will manage groups and verify proofs
  /// @param _groupId The group ID of the World ID
  /// @param _externalNullifierHash The nullifier hash that will be used to verify proofs
  constructor(
    IWorldIDGroups _worldIdRouter,
    uint256 _groupId,
    uint256 _externalNullifierHash,
    uint256 _maxGrantId,
    uint256 _currentGrantId
  ) Ownable(msg.sender) {
    if (_maxGrantId == 0) revert InvalidConfiguration();
    if (_maxGrantId <= _currentGrantId) revert InvalidConfiguration();
    if (address(_worldIdRouter) == address(0)) revert InvalidConfiguration();

    groupId = _groupId;
    maxGrantId = _maxGrantId;
    worldIdRouter = _worldIdRouter;
    currentGrantId = _currentGrantId;
    externalNullifierHash = _externalNullifierHash;

    emit GrantRegistrarInitialized(
      worldIdRouter,
      groupId,
      externalNullifierHash,
      maxGrantId,
      currentGrantId
    );
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                               MAIN LOGIC                                ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Registers a wallet to receive grants
  /// @param receiver The address that will be able to claim grants
  /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
  /// @param nullifierHash The nullifier for this proof, preventing double signaling
  /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
  /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
  function verify(
    address receiver,
    uint256 root,
    uint256 nullifierHash,
    uint256[8] calldata proof
  ) external payable {
    if (nullifierHashes[nullifierHash] <= maxGrantId) revert InvalidNullifier();

    worldIdRouter.verifyProof(
      root,
      groupId,
      uint256(keccak256(abi.encodePacked(receiver, maxGrantId))) >> 8,
      nullifierHash,
      externalNullifierHash,
      proof
    );

    expiryGrantIds[receiver] = maxGrantId;
    nullifierHashes[nullifierHash] = maxGrantId;
  }

  /// @notice Checks if a grant can be claimed by a receiver
  /// @param receiver The address that will be able to claim grants
  /// @param grantId The grant ID to check
  /// @return Whether the grant can be claimed.
  function canClaimGrant(address receiver, uint256 grantId) external view returns (bool) {
    return expiryGrantIds[receiver] >= grantId;
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                               CONFIG LOGIC                             ///
  //////////////////////////////////////////////////////////////////////////////

  // @notice Update the worldIdRouter
  /// @param _worldIdRouter The new worldIdRouter
  function setWorldIdRouter(IWorldIDGroups _worldIdRouter) external onlyOwner {
    if (address(_worldIdRouter) == address(0)) revert InvalidConfiguration();

    worldIdRouter = _worldIdRouter;
    emit WorldIdRouterUpdated(_worldIdRouter);
  }

  /// @notice Update the groupId
  /// @param _groupId The new groupId
  function setGroupId(uint256 _groupId) external onlyOwner {
    groupId = _groupId;

    emit GroupIdUpdated(_groupId);
  }

  /// @notice Update the current grant ID
  /// @param _currentGrantId The new current grant ID
  function setCurrentGrant(uint256 _currentGrantId) external onlyOwner {
    if (_currentGrantId <= currentGrantId) revert InvalidConfiguration();

    currentGrantId = _currentGrantId;
    emit CurrentGrantIdUpdated(currentGrantId);
  }

  /// @notice Update the max grant ID
  /// @param _maxGrantId The new max grant ID
  function setMaxGrantId(uint256 _maxGrantId) external onlyOwner {
    if (_maxGrantId <= currentGrantId) revert InvalidConfiguration();

    maxGrantId = _maxGrantId;
    emit MaxGrantIdUpdated(maxGrantId);
  }

  /// @notice Prevents the owner from renouncing ownership
  /// @dev onlyOwner
  function renounceOwnership() public view override onlyOwner {
    revert CannotRenounceOwnership();
  }
}
