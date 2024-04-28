// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGrant } from './IGrant.sol';
import { GrantRegistrar } from './GrantRegistrar.sol';
import { Ownable } from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import { ERC20 } from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import { ECDSA } from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
import { Ownable2Step } from 'openzeppelin-contracts/contracts/access/Ownable2Step.sol';
import { SafeERC20 } from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

/// @title RecurringGrantDrop
/// @author Worldcoin
contract RecurringGrantDrop is Ownable2Step {
  ///////////////////////////////////////////////////////////////////////////////
  ///                              CONFIG STORAGE                            ///
  //////////////////////////////////////////////////////////////////////////////

  /// @dev The GrantRegistrar instance that will be used for gating claims
  GrantRegistrar public grantRegistrar;

  /// @notice The ERC20 token airdropped
  ERC20 public token;

  /// @notice The address that holds the tokens that are being airdropped
  /// @dev Make sure the holder has approved spending for this contract!
  address public holder;

  /// @notice The grant instance used
  IGrant public grant;

  /// @notice Whether a particular grantId has been claimed by an address
  mapping(uint256 => mapping(address => bool)) public hasClaimedGrant;

  ///////////////////////////////////////////////////////////////////////////////
  ///                                  ERRORS                                ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Error in case the configuration is invalid.
  error InvalidConfiguration();

  /// @notice Error in case the receiver can't claim the grant or is the zero address.
  error InvalidReceiver();

  /// @notice Error in case the receiver is zero address.
  error InvalidTimestamp();

  /// @notice Thrown when passed an invalid caller address
  error UnauthorizedSigner();

  /// @notice Emmitted in revert if the owner attempts to resign ownership.
  error CannotRenounceOwnership();

  ///////////////////////////////////////////////////////////////////////////////
  ///                                  EVENTS                                ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Emitted when a grant is successfully claimed
  /// @param _grantRegistrar The GrantRegistrar that will gate the claims
  /// @param _token The ERC20 token that will be airdropped
  /// @param _holder The address holding the tokens that will be airdropped
  /// @param _grant The grant that contains the amounts and validity
  event RecurringGrantDropInitialized(
    GrantRegistrar _grantRegistrar,
    ERC20 _token,
    address _holder,
    IGrant _grant
  );

  /// @notice Emitted when a grant is successfully claimed
  /// @param receiver The address that received the tokens
  event GrantClaimed(uint256 grantId, address receiver);

  /// @notice Emitted when the grantRegistrar is changed
  /// @param grantRegistrar The new GrantRegistrar instance
  event GrantRegistrarUpdated(GrantRegistrar grantRegistrar);

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
  /// @param _grantRegistrar The GrantRegistrar that will gate the claims
  /// @param _token The ERC20 token that will be airdropped
  /// @param _holder The address holding the tokens that will be airdropped
  /// @param _grant The grant that contains the amounts and validity
  constructor(
    GrantRegistrar _grantRegistrar,
    ERC20 _token,
    address _holder,
    IGrant _grant
  ) Ownable(msg.sender) {
    if (address(_grantRegistrar) == address(0)) revert InvalidConfiguration();
    if (address(_token) == address(0)) revert InvalidConfiguration();
    if (address(_holder) == address(0)) revert InvalidConfiguration();
    if (address(_grant) == address(0)) revert InvalidConfiguration();

    grantRegistrar = _grantRegistrar;
    token = _token;
    holder = _holder;
    grant = _grant;

    emit RecurringGrantDropInitialized(grantRegistrar, token, holder, grant);
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                               CLAIM LOGIC                               ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Claim the airdrop
  /// @param grantId The grant ID to claim
  /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
  function claim(uint256 grantId, address receiver) external {
    checkClaim(grantId, receiver);

    hasClaimedGrant[grantId][receiver] = true;

    SafeERC20.safeTransferFrom(token, holder, receiver, grant.getAmount(grantId));

    emit GrantClaimed(grantId, receiver);
  }

  /// @notice Check whether a claim is valid
  /// @param grantId The grant ID to claim
  /// @param receiver The address that will receive the tokens
  function checkClaim(uint256 grantId, address receiver) public view {
    if (
      receiver == address(0) ||
      hasClaimedGrant[grantId][receiver] ||
      !grantRegistrar.canClaimGrant(receiver, grantId)
    ) revert InvalidReceiver();

    grant.checkValidity(grantId);
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                               CONFIG LOGIC                             ///
  //////////////////////////////////////////////////////////////////////////////

  /// @notice Update the grantRegistrar
  /// @param _grantRegistrar The new grantRegistrar
  function setGrantRegistrar(GrantRegistrar _grantRegistrar) external onlyOwner {
    if (address(_grantRegistrar) == address(0)) revert InvalidConfiguration();

    grantRegistrar = _grantRegistrar;
    emit GrantRegistrarUpdated(_grantRegistrar);
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
