pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {WLDGrant} from "src/WLDGrant.sol";

/// @title Deployment script for WLDGrant
/// @author Worldcoin
contract DeployWLDGrant is Script {
    function run() external {
        vm.startBroadcast();
        new WLDGrant();
        vm.stopBroadcast();
    }
}
