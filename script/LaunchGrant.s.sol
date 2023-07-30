pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {LaunchGrant} from "src/LaunchGrant.sol";

/// @title Deployment script for LaunchGrant
/// @author Worldcoin
contract DeployLaunchGrant is Script {

    LaunchGrant grant;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));

    function run() external {
        vm.startBroadcast(privateKey);
        new LaunchGrant();
        vm.stopBroadcast();
    }
}