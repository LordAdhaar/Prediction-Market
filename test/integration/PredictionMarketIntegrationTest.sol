// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../../src/PredictionMarketEngine.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract PredictionMarketEngineTest is Test {
    PredictionMarketEngine public predictionMarketEngine;
    ERC20Mock public predictionMarketToken;

    address public owner = makeAddr("Owner");
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");
    address public tom = makeAddr("Tom");

    uint256 public constant ALICE_STARTING_BALANCE = 4e18;
    uint256 public constant BOB_STARTING_BALANCE = 11e18;
    uint256 public constant TOM_STARTING_BALANCE = 15e18;

    function setUp() external {
        predictionMarketToken = new ERC20Mock("Prediction Market Token", "PMT", address(this), 1000e18);
        predictionMarketEngine = new PredictionMarketEngine(owner, address(predictionMarketToken));

        predictionMarketToken.mint(alice, ALICE_STARTING_BALANCE);
        predictionMarketToken.mint(bob, BOB_STARTING_BALANCE);
        predictionMarketToken.mint(tom, TOM_STARTING_BALANCE);
    }

    function testPredictionMarketEngine() external {
        vm.prank(owner);
        uint256 marketId = predictionMarketEngine.createMarket("Who will win the election?", "Alice", "Bob", 100);

        vm.startPrank(alice);
        predictionMarketToken.approve(address(predictionMarketEngine), 100e18);
        predictionMarketEngine.buyShares(marketId, true, 4e18);
        vm.stopPrank();

        vm.startPrank(bob);
        predictionMarketToken.approve(address(predictionMarketEngine), 100e18);
        predictionMarketEngine.buyShares(marketId, true, 11e18);
        vm.stopPrank();

        vm.startPrank(tom);
        predictionMarketToken.approve(address(predictionMarketEngine), 100e18);
        predictionMarketEngine.buyShares(marketId, false, 15e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 100);
        vm.prank(owner);
        predictionMarketEngine.resolveMarket(marketId, PredictionMarketEngine.MarketOutcome.OPTION_A);

        vm.startPrank(alice);
        predictionMarketEngine.claimWinnings(marketId);
        vm.stopPrank();

        assertEq(predictionMarketToken.balanceOf(alice), 8e18);
    }
}
