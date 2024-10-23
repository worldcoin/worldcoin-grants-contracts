pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {NFC_ID_Batch} from "src/NFC_ID_Batch.sol";

/// @title Deployment script for NFC_ID_Batch
/// @author Worldcoin
/// @notice Deploys the NFC_ID_Batch contract with the correct parameters
/// @dev You need to have the necessary values in scripts/.deploy-config.json in order for it to work.
/// Can be run by executing `make deploy-nfc-id-batch`
contract DeployRecurringGrantDrop is Script {
    NFC_ID_Batch public nfcIdBatch;

    ///////////////////////////////////////////////////////////////////
    ///                            CONFIG                           ///
    ///////////////////////////////////////////////////////////////////
    string public root = vm.projectRoot();
    string public path = string.concat(root, "/script/.deploy-config.json");
    string public json = vm.readFile(path);

    uint256 private privateKey = abi.decode(vm.parseJson(json, ".privateKey"), (uint256));
    address public erc20Address = abi.decode(vm.parseJson(json, ".erc20Address"), (address));
    address public holder = abi.decode(vm.parseJson(json, ".holderAddress"), (address));

    ///////////////////////////////////////////////////////////////////
    ///                          VARIABLES                          ///
    ///////////////////////////////////////////////////////////////////

    // Worldchain Allowance Module Address
    address public allowanceModule = 0xa9bcF56d9FCc0178414EF27a3d893C9469e437B7;

    ERC20 public token = ERC20(erc20Address);

    function run() external {
        vm.startBroadcast(privateKey);

        nfcIdBatch =
            new NFC_ID_Batch(allowanceModule, erc20Address, holder);

        vm.stopBroadcast();
    }
}
