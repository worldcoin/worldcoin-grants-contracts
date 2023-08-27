pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {StagingGrant} from "src/StagingGrant.sol";
import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";

/// @title Deployment script for StagingGrant
/// @author Worldcoin
contract DeployStagingGrant is Script {

    RecurringGrantDrop airdrop;
    StagingGrant grant;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config-staging.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));
    uint256 public amount = abi.decode(vm.parseJson(json, ".amount"), (uint256));
    uint256 public startOffset = abi.decode(vm.parseJson(json, ".startOffset"), (uint256));

    function run() external {
        vm.startBroadcast(privateKey);
        grant = new StagingGrant(startOffset, amount);

        airdrop = RecurringGrantDrop(0xC84337376696EfdefE38CD6112b4ad70E1EFCA95);
        airdrop.setGrant(grant);
        
        vm.stopBroadcast();
    }
}