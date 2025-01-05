// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {PredictionMarketToken} from "../../src/PredictionMarketToken.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract PredictionMarketEngineTest is Test {
    PredictionMarketToken public predictionMarketToken;

    address public owner = makeAddr("Owner");
    address public alice = makeAddr("Alice");

    function setUp() external {
        predictionMarketToken = new PredictionMarketToken(owner);
    }

    function testMint() external {
        vm.prank(owner);
        predictionMarketToken.mint(alice, 100);

        assertEq(predictionMarketToken.balanceOf(alice), 100);
    }
}
