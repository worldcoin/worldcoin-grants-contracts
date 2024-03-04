// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IRecurringGrantDrop} from "./IRecurringGrantDrop.sol";
import {ISwapRouter} from "v3-periphery/interfaces/ISwapRouter.sol";

/// @title GrantMiddleware
/// @author Worldcoin
/// @notice contract that takes fees on grant claims to pay for gas costs
contract GrantMiddleware is Ownable2Step {
    /// @notice WLD ERC20 token
    ERC20 public immutable WLD = ERC20(0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1);

    /// @notice Chainlink oracle for WLD/USDC
    ISwapRouter immutable UNISWAP_ROUTER = ISwapRouter(0xb5fBFEBA9848664fd1a49dC2a250d9B5D1294f2a);

    /// @notice Grant address
    IRecurringGrantDrop public grantAddress =
        IRecurringGrantDrop(0x7B46fFbC976db2F94C3B3CDD9EbBe4ab50E3d77d);

    /// @notice The relayers that will call the contract
    mapping(address => bool) public relayers;

    /// @notice This is the amount of WLD in wei for the grant. We don't want to read from the IGrant contract every time
    uint256 public grantAmount;

    /// @notice This is the fee amount in WLD in wei for the grant
    uint256 public feeAmount;

    /// @notice This is the min WLD amount before swapping and sending to feeAddress
    uint256 public transferThreshold;

    /// @notice This is the address that receives the fee
    address public feeAddress;

    /// @notice This is the token that WLD will be swapped into
    address public feeToken;

    /// @notice This is the WLD/feeToken pool on Uniswapv3
    uint24 public poolFee;

    /// @notice Thrown when the caller is not an allowed caller
    error NotRelayer(address account);

    /// @notice Emitted when a grant is successfully claimed
    /// @param receiver The address that received the tokens
    event GrantClaimed(address receiver);

    /**
     * @dev Throws if called by any account other than a relayer.
     */
    modifier onlyRelayer() {
        if (!relayers[msg.sender]) {
            revert NotRelayer(msg.sender);
        }
        _;
    }

    constructor(
        uint256 _feeAmount,
        address _feeAddress,
        uint256 _transferThreshold,
        address _feeToken,
        uint24 _poolFee
    ) Ownable(msg.sender) {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
        transferThreshold = _transferThreshold;
        feeToken = _feeToken;
        poolFee = _poolFee;

        // Set max approval once
        WLD.approve(address(UNISWAP_ROUTER), type(uint256).max);
    }

    function setFee(uint256 _feeAmount) external onlyOwner {
        feeAmount = _feeAmount;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function setTransferThreshold(uint256 _transferThreshold) external onlyOwner {
        transferThreshold = _transferThreshold;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = _feeToken;
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    /// @notice Claim the airdrop on behalf of the user, take a fee, and send the rest to the user.
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
    ) external onlyRelayer {
        // Send the grant to this contract first
        grantAddress.claim(grantId, address(this), root, nullifierHash, proof);
        uint256 wldUserAmount = grantAmount - feeAmount;
        WLD.transfer(receiver, wldUserAmount);
        emit GrantClaimed(receiver);

        uint256 feeBalance = WLD.balanceOf(address(this));

        if (feeBalance > transferThreshold) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(WLD),
                tokenOut: feeToken,
                fee: poolFee,
                recipient: feeAddress,
                deadline: block.timestamp,
                amountIn: feeBalance,
                // TODO: Should we set a min here or just take what the pool gives us
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            try UNISWAP_ROUTER.exactInputSingle(params) {}
            // Don't revert the user's grant claim if swap fails
            catch {}
        }
    }
}
