pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {RecurringGrantDrop} from "src/RecurringGrantDrop.sol";

/// @title AddAllowedNullifierHashBlocker Script
/// @author Worldcoin
/// @notice Sets an allowed nullifier hash blocker on a RGDrop contarct
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make add-allowed-nullifier-hash-blocker` in the shell.
contract AddAllowedNullifierHashBlocker is Script {
    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));
    address private rgdAddress = abi.decode(vm.parseJson(json, ".recurringGrantDropAddress"), (address));
    address private allowedNullifierHashBlocker = abi.decode(vm.parseJson(json, ".allowedNullifierHashBlocker"), (address));

    RecurringGrantDrop rgd = RecurringGrantDrop(rgdAddress);

    function run() external {
        vm.startBroadcast(privateKey);

        rgd.addAllowedNullifierHashBlocker(allowedNullifierHashBlocker);

        vm.stopBroadcast();
    }
}
