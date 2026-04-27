// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {GnosisSafe, AllowanceModule} from "./IAllowanceModule.sol";
import {IWorldIDVerifierV2} from "./IWorldIDVerifierV2.sol";

interface IWIP101 is IERC165 {
    error RpInvalidRequest(uint256 code);

    function verifyRpRequest(
        uint8 version,
        uint256 nonce,
        uint64 createdAt,
        uint64 expiresAt,
        uint256 action,
        bytes calldata data
    ) external view returns (bytes4 magicValue);
}

/// @title LockedOneTimeGrant
/// @author Worldcoin
/// @notice One-time, opt-in WLD grant with a fixed lockup and permissionless withdrawal.
contract LockedOneTimeGrant is Ownable2Step, IWIP101 {
    using SafeERC20 for ERC20;

    bytes4 public constant WIP101_MAGIC_VALUE = IWIP101.verifyRpRequest.selector;
    uint256 public constant WIP101_INVALID_VERSION = 1;
    uint256 public constant WIP101_INVALID_TIMESTAMP = 2;
    uint256 public constant WIP101_INVALID_ACTION = 3;
    uint256 public constant WIP101_UNSUPPORTED_AUX_DATA = 4;
    uint256 public constant WIP101_STOPPED = 5;

    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice World ID verifier for the new World ID protocol.
    IWorldIDVerifierV2 public worldIdVerifier;

    /// @notice The ERC20 token granted.
    ERC20 public immutable token;

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
    /// @dev Stored as uint96 because the immutable token is WLD; this supports ~79.2B
    ///      tokens at 18 decimals and matches the Safe AllowanceModule amount type.
    uint96 public grantAmount;

    /// @notice Lockup period applied to new claimants.
    uint64 public lockupPeriod;

    /// @notice Whether new grant claims and WIP-101 proof requests are stopped.
    bool public stopped;

    /// @notice Claim details keyed by World ID nullifier.
    mapping(uint256 => Claim) public claims;

    /// @notice Registered claim nullifier keyed by wallet address.
    /// @dev Intentionally never cleared so a wallet cannot be reused after withdrawal.
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

    /// @notice Thrown when grant claiming is stopped.
    error GrantStopped();

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

    event WorldIdVerifierUpdated(IWorldIDVerifierV2 indexed worldIdVerifier);
    event HolderUpdated(address indexed holder);
    event AllowanceModuleUpdated(address indexed allowanceModule);
    event GrantParametersUpdated(uint96 grantAmount, uint64 lockupPeriod);
    event CredentialGenesisIssuedAtMinUpdated(uint256 credentialGenesisIssuedAtMin);
    event StoppedUpdated(bool stopped);

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
        // World ID actions are field elements. The top byte must be zero after hash-to-field.
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
    /// @param expiresAtMin Minimum credential expiration used in the World ID proof. The verifier
    ///        rejects values that are too old for its configured expiration threshold.
    /// @param proof Encoded World ID proof. The fifth element is the World ID registry root.
    function claim(
        address receiver,
        uint256 nullifierHash,
        uint256 nonce,
        uint64 expiresAtMin,
        uint256[5] calldata proof
    ) external {
        if (stopped) revert GrantStopped();

        checkClaim(receiver, nullifierHash, nonce, expiresAtMin, proof);

        uint64 claimedAt = uint64(block.timestamp);
        uint64 unlockAt = claimedAt + lockupPeriod;
        uint96 amount = grantAmount;

        claims[nullifierHash] = Claim({
            receiver: receiver,
            amount: amount,
            claimedAt: claimedAt,
            unlockAt: unlockAt,
            withdrawn: false
        });
        registeredNullifierHashes[receiver] = nullifierHash;

        allowanceModule.executeAllowanceTransfer(
            holder, address(token), payable(address(this)), amount
        );

        emit GrantClaimed(nullifierHash, receiver, amount, unlockAt);
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
        token.safeTransfer(grant.receiver, grant.amount);

        emit GrantWithdrawn(nullifierHash, grant.receiver, grant.amount);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               WIP-101                                  ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Returns ERC-165 support for WIP-101 RP signer checks.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IWIP101).interfaceId;
    }

    /// @notice Validates OPRF proof requests when this contract is registered as the RP signer.
    /// @dev The OPRF nodes call this before producing a proof. This deliberately authorizes only
    ///      this grant's configured action and rejects all auxiliary data. Requests must already be
    ///      live: `createdAt <= block.timestamp < expiresAt`. The nonce is intentionally unused
    ///      here; uniqueness is enforced by the OPRF nodes and by consuming the World ID nullifier
    ///      during claim.
    function verifyRpRequest(
        uint8 version,
        uint256,
        uint64 createdAt,
        uint64 expiresAt,
        uint256 requestAction,
        bytes calldata data
    ) external view returns (bytes4) {
        if (stopped) revert IWIP101.RpInvalidRequest(WIP101_STOPPED);
        if (version != 1) revert IWIP101.RpInvalidRequest(WIP101_INVALID_VERSION);
        if (createdAt > block.timestamp || createdAt > expiresAt || expiresAt <= block.timestamp) {
            revert IWIP101.RpInvalidRequest(WIP101_INVALID_TIMESTAMP);
        }
        if (requestAction != action) revert IWIP101.RpInvalidRequest(WIP101_INVALID_ACTION);
        if (data.length != 0) revert IWIP101.RpInvalidRequest(WIP101_UNSUPPORTED_AUX_DATA);

        return WIP101_MAGIC_VALUE;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                VIEWS                                    ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the claim registered by a receiver, or an empty claim if none exists.
    function claimFor(address receiver) public view returns (Claim memory) {
        return claims[registeredNullifierHashes[receiver]];
    }

    /// @notice Returns the receiver's claimed balance until it is withdrawn.
    function grantBalanceOf(address receiver) public view returns (uint256) {
        Claim memory grant = claimFor(receiver);
        if (grant.receiver == address(0) || grant.withdrawn) return 0;
        return grant.amount;
    }

    /// @notice Returns the receiver's balance that is still locked.
    function lockedBalanceOf(address receiver) external view returns (uint256) {
        Claim memory grant = claimFor(receiver);
        if (grant.receiver == address(0) || grant.withdrawn || block.timestamp >= grant.unlockAt) {
            return 0;
        }
        return grant.amount;
    }

    /// @notice Returns the receiver's unlocked balance that has not yet been withdrawn.
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
    /// @dev Drops the top byte so the result fits the BN254 scalar field.
    function hashToField(bytes memory value) public pure returns (uint256) {
        return uint256(keccak256(value)) >> 8;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONFIG LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the World ID verifier used for future claims.
    /// @dev Existing claims are already funded and do not call the verifier during withdrawal.
    function setWorldIdVerifier(IWorldIDVerifierV2 _worldIdVerifier) external onlyOwner {
        if (address(_worldIdVerifier) == address(0)) revert InvalidConfiguration();

        worldIdVerifier = _worldIdVerifier;
        emit WorldIdVerifierUpdated(_worldIdVerifier);
    }

    /// @notice Updates the Safe used to fund future claims.
    /// @dev Existing claims are unaffected because funds are pulled into this contract at claim time.
    function setHolder(address _holder) external onlyOwner {
        if (_holder == address(0)) revert InvalidConfiguration();

        holder = GnosisSafe(_holder);
        emit HolderUpdated(_holder);
    }

    /// @notice Updates the Safe AllowanceModule used to fund future claims.
    /// @dev Existing claims are unaffected because funds are pulled into this contract at claim time.
    function setAllowanceModule(address _allowanceModule) external onlyOwner {
        if (_allowanceModule == address(0)) revert InvalidConfiguration();

        allowanceModule = AllowanceModule(_allowanceModule);
        emit AllowanceModuleUpdated(_allowanceModule);
    }

    /// @notice Updates the amount and lockup period applied to future claims.
    /// @dev Existing claims keep their amount and unlock timestamp.
    function setGrantParameters(uint96 _grantAmount, uint64 _lockupPeriod) external onlyOwner {
        if (_grantAmount == 0) revert InvalidConfiguration();
        if (_lockupPeriod == 0) revert InvalidConfiguration();

        grantAmount = _grantAmount;
        lockupPeriod = _lockupPeriod;
        emit GrantParametersUpdated(_grantAmount, _lockupPeriod);
    }

    /// @notice Updates the minimum credential genesis issued-at timestamp for future claims.
    /// @dev The owner can raise or lower this value to correct the launch-date eligibility window.
    function setCredentialGenesisIssuedAtMin(uint256 _credentialGenesisIssuedAtMin)
        external
        onlyOwner
    {
        if (_credentialGenesisIssuedAtMin == 0) revert InvalidConfiguration();

        credentialGenesisIssuedAtMin = _credentialGenesisIssuedAtMin;
        emit CredentialGenesisIssuedAtMinUpdated(_credentialGenesisIssuedAtMin);
    }

    /// @notice Stops or resumes future claims and WIP-101 proof requests.
    /// @dev Withdrawals for already funded claims are intentionally unaffected.
    function setStopped(bool _stopped) external onlyOwner {
        stopped = _stopped;
        emit StoppedUpdated(_stopped);
    }

    /// @notice Prevents the owner from renouncing ownership.
    /// @dev onlyOwner
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
