pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";
import {RecurringGrantDropLegacy} from "src/RecurringGrantDropLegacy.sol";
import {StagingGrant} from "src/StagingGrantPreGrant4.sol";
import {LaunchGrantLegacy} from "src/LaunchGrantLegacy.sol";
import {WLDGrant} from "src/WLDGrantPreGrant4_new.sol";
import {IGrant} from "src/IGrantPreGrant4.sol";

/// @title Deployment script for RecurringGrantDrop
/// @author Worldcoin
/// @notice Deploys the RecurringGrantDrop contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-airdrop` (assumes a deployment of world-id-contracts or a mock)
contract DeployWLDGrantPreGrant4_new is Script {
    RecurringGrantDrop public airdrop;
    IGrant grant;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));

    function run() external {
        vm.startBroadcast(privateKey);

        grant = new WLDGrant();

        vm.stopBroadcast();
    }
}
