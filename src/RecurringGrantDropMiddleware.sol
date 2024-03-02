// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IRecurringGrantDrop } from "./IRecurringGrantDrop.sol";

interface IChainlinkAggregator {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

/// @title GrantMiddleware
/// @author Worldcoin
/// @notice contract that takes fees on grant claims to pay for gas costs
contract GrantMiddleware is Ownable2Step {
    /// @notice WLD ERC20 token
    ERC20 public immutable WLD = ERC20(0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1);

    /// @notice USDC ERC20 token
    ERC20 immutable USDC = ERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);

    /// @notice Chainlink oracle for WLD/USDC
    IChainlinkAggregator immutable ORACLE = IChainlinkAggregator(0x4e1C6B168DCFD7758bC2Ab9d2865f1895813D236);

    /// @notice The relayers that will call the contract
    mapping(address => bool) public relayers;

    /// @notice This is the fee amount in cents. 100 = $1 fee
    uint public fee;

    /// @notice This is the amount of WLD in wei for the grant. We don't want to read from the contract every time 
    uint public grantAmount;

    /// @notice This is the address that receives the fee
    address public feeAddress;

    /// @notice Grant address 
    IRecurringGrantDrop public grantAddress = IRecurringGrantDrop(0x7B46fFbC976db2F94C3B3CDD9EbBe4ab50E3d77d);

    /// @notice Thrown when the caller is not the owner
    error NotRelayer(address account);

    /// @notice Thrown when the caller is not the owner
    error NotOwner(address account);

    constructor(uint _fee, address _feeAddress) Ownable(msg.sender) {
        fee = _fee;
        feeAddress = _feeAddress;
    }

    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /// @notice Claim the airdrop on behalf of the user, take a fee, and send the rest to the user.
    /// @param grantId The grant ID to claim
    /// @param receiver The address that will receive the tokens (this is also the signal of the ZKP)
    /// @param root The root of the Merkle tree (signup-sequencer or world-id-contracts provides this)
    /// @param nullifierHash The nullifier for this proof, preventing double signaling
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID
    /// @dev hashToField function docs are in lib/world-id-contracts/src/libraries/ByteHasher.sol
    function claim(uint256 grantId, address receiver, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)
        external
    {
        // Send the grant to this contract first
        grantAddress.claim(grantId, address(this), root, nullifierHash, proof);

    
        int256 latestRate = ORACLE.latestAnswer();
        require(latestRate > 0, "Invalid rate from oracle");

        // TODO: Write test for unit conversion
        uint256 tokenAmount = fee * (10 ** (WLD.decimals() + ORACLE.decimals() - 8)) / uint256(latestRate);

        // Swap

        // Calculate the grantAmount
        // uint grantAmount = grantAddress.grants(grantId).amount;

        // checkClaim(grantId, receiver, root, nullifierHash, proof);

        // nullifierHashes[nullifierHash] = true;

        // SafeERC20.safeTransferFrom(token, holder, receiver, grant.getAmount(grantId));

        // emit GrantClaimed(grantId, receiver);
    }

    // /// @notice sets the relayer that can call the transfer() method
    // /// @param _relayer the new relayer address
    // /// @custom:reverts NotOwner if the caller is not the owner (the Safe proxy - HOLDER)
    // function setRelayer(address _relayer) external {
    //     if (msg.sender != address(HOLDER)) revert NotOwner(msg.sender);
    //     relayer = _relayer;
    // }
}
