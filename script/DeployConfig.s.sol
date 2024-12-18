// SPDX-License-Identifier: MIT
// solhint-disable private-vars-leading-underscore,no-console
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console2 as console} from "forge-std/console2.sol";

/// @title DeployConfig
/// @notice Represents the configuration required to deploy the system. It is expected
///         to read the file from JSON. A future improvement would be to have fallback
///         values if they are not defined in the JSON themselves.
contract DeployConfig is Script {
    string internal _json;

    string public name;
    string public symbol;

    string public nftName;
    string public nftSymbol;

    address public proxyAdminOwner;
    address public appAdmin;
    uint256 public dailyMintLimit;

    constructor(string memory _path) {
        console.log("DeployConfig: reading file %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            _json = data;
        } catch {
            console.log(
                "Warning: unable to read config. Do not deploy unless you are not using config."
            );
            return;
        }

        name = stdJson.readString(_json, "$.name");
        symbol = stdJson.readString(_json, "$.symbol");
        nftName = stdJson.readString(_json, "$.nftName");
        nftSymbol = stdJson.readString(_json, "$.nftSymbol");
        proxyAdminOwner = stdJson.readAddress(_json, "$.proxyAdminOwner");
        appAdmin = stdJson.readAddress(_json, "$.appAdmin");
        dailyMintLimit = stdJson.readUint(_json, "$.dailyMintLimit");
    }
}
