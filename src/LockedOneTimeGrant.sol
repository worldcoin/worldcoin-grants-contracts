// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {GnosisSafe, AllowanceModule} from "./IAllowanceModule.sol";
import {IWorldIDVerifierV2} from "./IWorldIDVerifierV2.sol";

/// @title LockedOneTimeGrant
/// @author Worldcoin
/// @notice One-time, opt-in WLD grant with a fixed lockup and permissionless withdrawal.
contract LockedOneTimeGrant is Ownable2Step {
    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice World ID verifier for the new World ID protocol.
    IWorldIDVerifierV2 public worldIdVerifier;

    /// @notice The ERC20 token granted.
    ERC20 public token;

    /// @notice Safe that grants allowances to this contract.
    GnosisSafe public holder;

    /// @notice Safe AllowanceModule used to transfer WLD.
    AllowanceModule public allowanceModule;

    /// @notice Registered relying party id used in World ID proofs.
    uint64 public immutable rpId;

    /// @notice World ID action used for this one-time claim.
    uint256 public immutable action;

    /// @notice Credential issuer schema id for Orb credentials.
    uint64 public immutable issuerSchemaId;

    /// @notice Minimum credential genesis issued-at timestamp for eligibility.
    uint256 public credentialGenesisIssuedAtMin;

    /// @notice Amount granted to new claimants.
    uint96 public grantAmount;

    /// @notice Lockup period applied to new claimants.
    uint64 public lockupPeriod;

    /// @notice Claim details keyed by World ID nullifier.
    mapping(uint256 => Claim) public claims;

    /// @notice Registered claim nullifier keyed by wallet address.
    mapping(address => uint256) public registeredNullifierHashes;

    struct Claim {
        address receiver;
        uint96 amount;
        uint64 claimedAt;
        uint64 unlockAt;
        bool withdrawn;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Error in case the configuration is invalid.
    error InvalidConfiguration();

    /// @notice Error in case the receiver is zero address.
    error InvalidReceiver();

    /// @notice Error in case the nullifier is zero.
    error InvalidNullifier();

    /// @notice Thrown when the nullifier already has a claim.
    error GrantAlreadyClaimed();

    /// @notice Thrown when the receiver already registered a claim.
    error ReceiverAlreadyRegistered();

    /// @notice Thrown when no grant was claimed for a nullifier.
    error GrantNotClaimed();

    /// @notice Thrown when the lockup has not ended yet.
    error GrantLocked(uint256 unlockAt);

    /// @notice Thrown when a grant was already withdrawn.
    error GrantAlreadyWithdrawn();

    /// @notice Emitted in revert if the owner attempts to resign ownership.
    error CannotRenounceOwnership();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    event LockedOneTimeGrantInitialized(
        IWorldIDVerifierV2 indexed worldIdVerifier,
        ERC20 indexed token,
        address indexed holder,
        address allowanceModule,
        uint64 rpId,
        uint256 action,
        uint64 issuerSchemaId,
        uint256 credentialGenesisIssuedAtMin,
        uint96 grantAmount,
        uint64 lockupPeriod
    );

    /// @notice Emitted when a proof-backed opt-in registers a locked grant.
    event GrantClaimed(
        uint256 indexed nullifierHash, address indexed receiver, uint96 amount, uint64 unlockAt
    );

    /// @notice Emitted when a locked grant is withdrawn to the registered wallet.
    event GrantWithdrawn(uint256 indexed nullifierHash, address indexed receiver, uint96 amount);

    event WorldIdVerifierUpdated(IWorldIDVerifierV2 worldIdVerifier);
    event TokenUpdated(ERC20 token);
    event HolderUpdated(address holder);
    event AllowanceModuleUpdated(address allowanceModule);
    event GrantParametersUpdated(uint96 grantAmount, uint64 lockupPeriod);
    event CredentialGenesisIssuedAtMinUpdated(uint256 credentialGenesisIssuedAtMin);

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                              ///
    //////////////////////////////////////////////////////////////////////////////

    constructor(
        IWorldIDVerifierV2 _worldIdVerifier,
        ERC20 _token,
        address _holder,
        address _allowanceModule,
        uint64 _rpId,
        uint256 _action,
        uint64 _issuerSchemaId,
        uint256 _credentialGenesisIssuedAtMin,
        uint96 _grantAmount,
        uint64 _lockupPeriod
    ) Ownable(msg.sender) {
        if (address(_worldIdVerifier) == address(0)) {
            revert InvalidConfiguration();
        }
        if (address(_token) == address(0)) revert InvalidConfiguration();
        if (_holder == address(0)) revert InvalidConfiguration();
        if (_allowanceModule == address(0)) revert InvalidConfiguration();
        if (_rpId == 0) revert InvalidConfiguration();
        if (_action == 0 || uint8(_action >> 248) != 0) revert InvalidConfiguration();
        if (_issuerSchemaId == 0) revert InvalidConfiguration();
        if (_credentialGenesisIssuedAtMin == 0) revert InvalidConfiguration();
        if (_grantAmount == 0) revert InvalidConfiguration();
        if (_lockupPeriod == 0) revert InvalidConfiguration();

        worldIdVerifier = _worldIdVerifier;
        token = _token;
        holder = GnosisSafe(_holder);
        allowanceModule = AllowanceModule(_allowanceModule);
        rpId = _rpId;
        action = _action;
        issuerSchemaId = _issuerSchemaId;
        credentialGenesisIssuedAtMin = _credentialGenesisIssuedAtMin;
        grantAmount = _grantAmount;
        lockupPeriod = _lockupPeriod;

        emit LockedOneTimeGrantInitialized(
            _worldIdVerifier,
            _token,
            _holder,
            _allowanceModule,
            _rpId,
            _action,
            _issuerSchemaId,
            _credentialGenesisIssuedAtMin,
            _grantAmount,
            _lockupPeriod
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CLAIM LOGIC                               ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Register a one-time locked grant after verifying a World ID uniqueness proof.
    /// @param receiver The wallet registered for the future withdrawal.
    /// @param nullifierHash The World ID uniqueness nullifier.
    /// @param nonce Unique nonce used in the World ID proof.
    /// @param expiresAtMin Minimum credential expiration used in the World ID proof.
    /// @param proof Encoded World ID proof. The fifth element is the World ID registry root.
    function claim(
        address receiver,
        uint256 nullifierHash,
        uint256 nonce,
        uint64 expiresAtMin,
        uint256[5] calldata proof
    ) external {
        checkClaim(receiver, nullifierHash, nonce, expiresAtMin, proof);

        uint64 claimedAt = uint64(block.timestamp);
        uint64 unlockAt = claimedAt + lockupPeriod;

        claims[nullifierHash] = Claim({
            receiver: receiver,
            amount: grantAmount,
            claimedAt: claimedAt,
            unlockAt: unlockAt,
            withdrawn: false
        });
        registeredNullifierHashes[receiver] = nullifierHash;

        emit GrantClaimed(nullifierHash, receiver, grantAmount, unlockAt);
    }

    /// @notice Check whether a grant registration is valid.
    /// @dev This verifies against the new World ID protocol verifier and forwards
    ///      credentialGenesisIssuedAtMin as the eligibility date.
    function checkClaim(
        address receiver,
        uint256 nullifierHash,
        uint256 nonce,
        uint64 expiresAtMin,
        uint256[5] calldata proof
    ) public view {
        if (receiver == address(0)) revert InvalidReceiver();
        if (nullifierHash == 0) revert InvalidNullifier();
        if (claims[nullifierHash].receiver != address(0)) revert GrantAlreadyClaimed();
        if (registeredNullifierHashes[receiver] != 0) revert ReceiverAlreadyRegistered();

        worldIdVerifier.verify(
            nullifierHash,
            action,
            rpId,
            nonce,
            signalHash(receiver),
            expiresAtMin,
            issuerSchemaId,
            credentialGenesisIssuedAtMin,
            proof
        );
    }

    /// @notice Withdraw a locked grant to the wallet registered during claim.
    /// @dev Permissionless by design; funds always go to the registered receiver.
    function withdraw(uint256 nullifierHash) external {
        Claim storage grant = claims[nullifierHash];

        if (grant.receiver == address(0)) revert GrantNotClaimed();
        if (grant.withdrawn) revert GrantAlreadyWithdrawn();
        if (block.timestamp < grant.unlockAt) revert GrantLocked(grant.unlockAt);

        grant.withdrawn = true;
        allowanceModule.executeAllowanceTransfer(
            holder, address(token), payable(grant.receiver), grant.amount
        );

        emit GrantWithdrawn(nullifierHash, grant.receiver, grant.amount);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                VIEWS                                    ///
    //////////////////////////////////////////////////////////////////////////////

    function claimFor(address receiver) public view returns (Claim memory) {
        return claims[registeredNullifierHashes[receiver]];
    }

    function grantBalanceOf(address receiver) public view returns (uint256) {
        Claim memory grant = claimFor(receiver);
        if (grant.receiver == address(0) || grant.withdrawn) return 0;
        return grant.amount;
    }

    function lockedBalanceOf(address receiver) external view returns (uint256) {
        Claim memory grant = claimFor(receiver);
        if (grant.receiver == address(0) || grant.withdrawn || block.timestamp >= grant.unlockAt) {
            return 0;
        }
        return grant.amount;
    }

    function claimableBalanceOf(address receiver) external view returns (uint256) {
        Claim memory grant = claimFor(receiver);
        if (grant.receiver == address(0) || grant.withdrawn || block.timestamp < grant.unlockAt) {
            return 0;
        }
        return grant.amount;
    }

    /// @notice World ID signal hash for a wallet address.
    function signalHash(address receiver) public pure returns (uint256) {
        return hashToField(abi.encodePacked(receiver));
    }

    /// @notice Reduces a hash to the field used by World ID public inputs.
    function hashToField(bytes memory value) public pure returns (uint256) {
        return uint256(keccak256(value)) >> 8;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONFIG LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

    function setWorldIdVerifier(IWorldIDVerifierV2 _worldIdVerifier) external onlyOwner {
        if (address(_worldIdVerifier) == address(0)) revert InvalidConfiguration();

        worldIdVerifier = _worldIdVerifier;
        emit WorldIdVerifierUpdated(_worldIdVerifier);
    }

    function setToken(ERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert InvalidConfiguration();

        token = _token;
        emit TokenUpdated(_token);
    }

    function setHolder(address _holder) external onlyOwner {
        if (_holder == address(0)) revert InvalidConfiguration();

        holder = GnosisSafe(_holder);
        emit HolderUpdated(_holder);
    }

    function setAllowanceModule(address _allowanceModule) external onlyOwner {
        if (_allowanceModule == address(0)) revert InvalidConfiguration();

        allowanceModule = AllowanceModule(_allowanceModule);
        emit AllowanceModuleUpdated(_allowanceModule);
    }

    function setGrantParameters(uint96 _grantAmount, uint64 _lockupPeriod) external onlyOwner {
        if (_grantAmount == 0) revert InvalidConfiguration();
        if (_lockupPeriod == 0) revert InvalidConfiguration();

        grantAmount = _grantAmount;
        lockupPeriod = _lockupPeriod;
        emit GrantParametersUpdated(_grantAmount, _lockupPeriod);
    }

    function setCredentialGenesisIssuedAtMin(uint256 _credentialGenesisIssuedAtMin)
        external
        onlyOwner
    {
        if (_credentialGenesisIssuedAtMin == 0) revert InvalidConfiguration();

        credentialGenesisIssuedAtMin = _credentialGenesisIssuedAtMin;
        emit CredentialGenesisIssuedAtMinUpdated(_credentialGenesisIssuedAtMin);
    }

    /// @notice Prevents the owner from renouncing ownership.
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
