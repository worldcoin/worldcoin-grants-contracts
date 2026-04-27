// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDVerifierV2} from "src/IWorldIDVerifierV2.sol";
import {LockedOneTimeGrant} from "src/LockedOneTimeGrant.sol";

/// @title Deployment script for LockedOneTimeGrant
/// @author Worldcoin
/// @notice Deploys the one-time locked grants contract.
/// @dev Required values in the deploy config JSON:
///      worldIDVerifierAddress, erc20Address, holderAddress, allowanceModuleAddress,
///      rpId, action, issuerSchemaId,
///      credentialGenesisIssuedAtMin, grantAmount, lockupPeriod.
///      Set DEPLOY_CONFIG_PATH to override the default script/.deploy-config.json path.
contract DeployLockedOneTimeGrant is Script {
    LockedOneTimeGrant public grantDrop;

    error MissingRpId();

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////

    string public root = vm.projectRoot();
    string public path =
        vm.envOr("DEPLOY_CONFIG_PATH", string.concat(root, "/script/.deploy-config.json"));
    string public json = vm.readFile(path);

    ///////////////////////////////////////////////////////////////////
    ///                          VARIABLES                          ///
    ///////////////////////////////////////////////////////////////////

    IWorldIDVerifierV2 public worldIdVerifier =
        IWorldIDVerifierV2(vm.parseJsonAddress(json, ".worldIDVerifierAddress"));

    ERC20 public token = ERC20(vm.parseJsonAddress(json, ".erc20Address"));
    address public holder = vm.parseJsonAddress(json, ".holderAddress");
    address public allowanceModule = vm.parseJsonAddress(json, ".allowanceModuleAddress");

    uint64 public rpId = uint64(vm.parseJsonUint(json, ".rpId"));
    uint256 public action = vm.parseJsonUint(json, ".action");
    uint64 public issuerSchemaId = uint64(vm.parseJsonUint(json, ".issuerSchemaId"));
    uint256 public credentialGenesisIssuedAtMin =
        vm.parseJsonUint(json, ".credentialGenesisIssuedAtMin");
    uint96 public grantAmount = uint96(vm.parseJsonUint(json, ".grantAmount"));
    uint64 public lockupPeriod = uint64(vm.parseJsonUint(json, ".lockupPeriod"));

    function run() external {
        if (rpId == 0) revert MissingRpId();

        vm.startBroadcast();

        grantDrop = new LockedOneTimeGrant(
            worldIdVerifier,
            token,
            holder,
            allowanceModule,
            rpId,
            action,
            issuerSchemaId,
            credentialGenesisIssuedAtMin,
            grantAmount,
            lockupPeriod
        );

        vm.stopBroadcast();
    }
}
