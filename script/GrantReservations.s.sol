pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {GrantReservations} from "src/GrantReservations.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";

/// @title Deployment script for GrantReservations
/// @author Worldcoin
/// @notice Deploys the GrantReservations contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-airdrop` (assumes a deployment of world-id-contracts or a mock)
contract DeployGrantReservations is Script {

    GrantReservations public reservations;
    
    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);
    
    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));
    RecurringGrantDrop public airdrop = RecurringGrantDrop(abi.decode(vm.parseJson(json, ".grantsContract"), (address)));
    
    ///////////////////////////////////////////////////////////////////
    ///                          VARIABLES                          ///
    ///////////////////////////////////////////////////////////////////
    
    function run() external {
        vm.startBroadcast(privateKey);

        reservations = new GrantReservations(airdrop);

        // Allow relayer addresses
        // Staging
        reservations.addAllowedSigner(address(0x10881c4f994F4d3d7Cb7e1EB3a17AD839eF970E6));
        // Production
        // TODO: reservations.addAllowedSigner(address(0x10881c4f994F4d3d7Cb7e1EB3a17AD839eF970E6));

        vm.stopBroadcast();
    }
}