pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IWorldIDGroups} from "world-id-contracts/interfaces/IWorldIDGroups.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";
import {GrantReservations} from "src/GrantReservations.sol";
import {MonthlyGrant} from "src/MonthlyGrant.sol";
import {HourlyGrant} from "src/HourlyGrant.sol";
import {WeeklyGrant} from "src/WeeklyGrant.sol";
import {LaunchGrant} from "src/LaunchGrant.sol";
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
    uint256 public startMonth = abi.decode(vm.parseJson(json, ".startMonth"), (uint256));
    uint256 public startYear = abi.decode(vm.parseJson(json, ".startYear"), (uint256));
    uint256 public amount = abi.decode(vm.parseJson(json, ".amount"), (uint256));
    uint256 public startOffset = abi.decode(vm.parseJson(json, ".startOffset"), (uint256));

    ERC20 public token = ERC20(erc20Address);

    function run() external {
        vm.startBroadcast(privateKey);

        if (staging) grant = new HourlyGrant(startOffset, amount);
        else grant = new LaunchGrant();

        airdrop = new RecurringGrantDrop(worldIdRouter, groupId, token, holder, grant);

        // Allow relayer addresses
        // airdrop.addAllowedCaller(address(0x65BF36D6499A504100EB504F0719271F5C4174ec));
        // airdrop.addAllowedCaller(address(0xd8F7d2d62514895475aFe0C7d75F31390Dd40DE4));
        // airdrop.addAllowedCaller(address(0xaBE494EaA4ED80de8583C49183E9cbdaDbc3b954));
        // airdrop.addAllowedCaller(address(0x4399fa85585F90DA110d5BA150fF96C763bc0Aba));
        // airdrop.addAllowedCaller(address(0xb54A5205eE454f48dDFc23CA26a3836Ba3daCC07));
        // airdrop.addAllowedCaller(address(0xD2d9438FBcAC1352FEeaf5130B1D725e07CB3b97));

        vm.stopBroadcast();
    }
}