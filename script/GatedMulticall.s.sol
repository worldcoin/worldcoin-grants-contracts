pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {GatedMulticall3} from "src/GatedMulticall/GatedMulticall.sol";

/// @title Deployment script for GatedMulticall
/// @author Worldcoin
/// @notice Deploys the GatedMulticall contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-gated-multicall`
contract GatedMulticall is Script {
    GatedMulticall3 public gatedMulticall;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));

    ///////////////////////////////////////////////////////////////////
    ///                          VARIABLES                          ///
    ///////////////////////////////////////////////////////////////////



    function run() external {
        vm.startBroadcast(privateKey);

        gatedMulticall = new GatedMulticall3();

        vm.stopBroadcast();
    }
}
