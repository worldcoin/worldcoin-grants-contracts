// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";
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
abstract contract LockedOneTimeGrantDeployConfig is Script {
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

    function _validateConfig() internal view {
        if (rpId == 0) revert MissingRpId();
    }

    function _constructorArgs() internal view returns (bytes memory) {
        return abi.encode(
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
    }

    function _creationCode() internal view returns (bytes memory) {
        return abi.encodePacked(type(LockedOneTimeGrant).creationCode, _constructorArgs());
    }

    function _deploy() internal returns (LockedOneTimeGrant) {
        return new LockedOneTimeGrant(
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
    }
}

contract DeployLockedOneTimeGrant is LockedOneTimeGrantDeployConfig {
    function run() external {
        _validateConfig();

        vm.startBroadcast();

        grantDrop = _deploy();

        vm.stopBroadcast();
    }
}

contract DeployLockedOneTimeGrantCreate2 is LockedOneTimeGrantDeployConfig {
    address public constant DEFAULT_CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    error UnexpectedDeploymentAddress(address expected, address actual);

    function create2Deployer() public returns (address) {
        return vm.envOr("CREATE2_DEPLOYER", DEFAULT_CREATE2_DEPLOYER);
    }

    function create2Salt() public returns (bytes32) {
        return vm.envBytes32("CREATE2_SALT");
    }

    function initCodeHash() public view returns (bytes32) {
        return keccak256(_creationCode());
    }

    function predictAddress(address deployer, bytes32 salt) public view returns (address) {
        return Create2.computeAddress(salt, initCodeHash(), deployer);
    }

    function predictedAddress() public returns (address) {
        return predictAddress(create2Deployer(), create2Salt());
    }

    function run() external {
        _validateConfig();

        bytes32 salt = create2Salt();
        address expected = predictAddress(create2Deployer(), salt);

        console2.log("Predicted LockedOneTimeGrant:", expected);

        vm.startBroadcast();

        grantDrop = new LockedOneTimeGrant{salt: salt}(
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

        if (address(grantDrop) != expected) {
            revert UnexpectedDeploymentAddress(expected, address(grantDrop));
        }

        console2.log("Deployed LockedOneTimeGrant:", address(grantDrop));
    }
}
