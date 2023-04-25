pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";
import {MonthlyGrant} from "src/MonthlyGrant.sol";
import {HourlyGrant} from "src/HourlyGrant.sol";
import {IGrant} from "src/IGrant.sol";

/// @title Deployment script for RecurringGrantDrop
/// @author Worldcoin
/// @notice Deploys the RecurringGrantDrop contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-airdrop` (assumes a deployment of world-id-contracts or a mock)
contract DeployRecurringGrantDrop is Script {

    RecurringGrantDrop public airdrop;
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

    address public worldIDRouterAddress = abi.decode(vm.parseJson(json, ".worldIDRouterAddress"), (address));
    IWorldIDGroups public worldIdRouter = IWorldIDGroups(worldIDRouterAddress);

    uint256 public groupId = abi.decode(vm.parseJson(json, ".groupId"), (uint256));
    address public erc20Address = abi.decode(vm.parseJson(json, ".erc20Address"), (address)); 
    address public holder = abi.decode(vm.parseJson(json, ".holderAddress"), (address));
    bool public staging = abi.decode(vm.parseJson(json, ".staging"), (bool));

    ERC20 public token = ERC20(erc20Address);

    function run() external {
        vm.startBroadcast(privateKey);

        IGrant grant;

        if (staging) grant = new HourlyGrant();
        else grant = new MonthlyGrant();

        airdrop = new RecurringGrantDrop(worldIdRouter, groupId, token, holder, grant);

        vm.stopBroadcast();
    }
}