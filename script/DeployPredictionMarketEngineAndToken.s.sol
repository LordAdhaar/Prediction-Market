// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "../lib/forge-std/src/Script.sol";
import {PredictionMarketEngine} from "../src/PredictionMarketEngine.sol";
import {PredictionMarketToken} from "../src/PredictionMarketToken.sol";

contract DeployPredictionMarketEngineAndToken is Script {
    PredictionMarketEngine public predictionMarketEngine;
    PredictionMarketToken public predictionMarketToken;

    address public owner = 0xb99822596ADa5fF795af305D98818E9ee4650C63;

    function run() public {
        vm.startBroadcast();

        predictionMarketToken = new PredictionMarketToken(owner);
        predictionMarketEngine = new PredictionMarketEngine(owner, address(predictionMarketToken));

        vm.stopBroadcast();
    }
}
