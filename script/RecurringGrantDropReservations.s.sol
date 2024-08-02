pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {RecurringGrantDropReservations} from "src/RecurringGrantDropReservations.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDropPreGrant4.sol";
import {WLDGrant} from "src/WLDGrantPreGrant4_new.sol";
import {IGrant} from "src/IGrantPreGrant4.sol";

/// @title Deployment script for RecurringGrantDrop
/// @author Worldcoin
/// @notice Deploys the RecurringGrantDrop contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-airdrop` (assumes a deployment of world-id-contracts or a mock)
contract DeployRecurringGrantDropReservations is Script {
    RecurringGrantDropReservations public airdrop;
    IGrant grant;

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

    address public worldIDRouterAddress =
        abi.decode(vm.parseJson(json, ".worldIDRouterAddress"), (address));
    IWorldIDGroups public worldIdRouter = IWorldIDGroups(worldIDRouterAddress);

    RecurringGrantDrop public recurringGrantDropAddress = RecurringGrantDrop(abi.decode(vm.parseJson(json, ".recurringGrantDropAddress"), (address)));
    uint256 public groupId = abi.decode(vm.parseJson(json, ".groupId"), (uint256));
    address public erc20Address = abi.decode(vm.parseJson(json, ".erc20Address"), (address));
    address public holder = abi.decode(vm.parseJson(json, ".holderAddress"), (address));

    ERC20 public token = ERC20(erc20Address);

    function run() external {
        vm.startBroadcast(privateKey);

        grant = new WLDGrant();

        airdrop = new RecurringGrantDropReservations(worldIdRouter, groupId, token, holder, grant, recurringGrantDropAddress);

        vm.stopBroadcast();
    }
}
