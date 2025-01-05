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

    uint256 public constant STARTING_BALANCE = 100e18;

    function setUp() external {
        predictionMarketToken = new ERC20Mock("Prediction Market Token", "PMT", address(this), 1000e18);
        predictionMarketEngine = new PredictionMarketEngine(owner, address(predictionMarketToken));

        predictionMarketToken.mint(alice, STARTING_BALANCE);
        predictionMarketToken.mint(bob, STARTING_BALANCE);
        predictionMarketToken.mint(tom, STARTING_BALANCE);
    }

    function testConstructor() external {
        assertEq(predictionMarketEngine.getOwner(), owner);
        assertEq(predictionMarketEngine.getPredictionMarketToken(), address(predictionMarketToken));

        assertEq(predictionMarketToken.balanceOf(alice), STARTING_BALANCE);
        assertEq(predictionMarketToken.balanceOf(bob), STARTING_BALANCE);
        assertEq(predictionMarketToken.balanceOf(tom), STARTING_BALANCE);
    }

    function testCreateMarket() external {
        vm.prank(owner);
        uint256 marketId = predictionMarketEngine.createMarket("Who will win the election?", "Alice", "Bob", 100);

        (, string memory question,,,,,,) = predictionMarketEngine.getMarketInfo(marketId);
        assertEq(question, "Who will win the election?");
    }

    function testBuyShares() external {
        vm.prank(owner);
        uint256 marketId = predictionMarketEngine.createMarket("Who will win the election?", "Alice", "Bob", 100);

        vm.startPrank(alice);
        predictionMarketToken.approve(address(predictionMarketEngine), 100);
        predictionMarketEngine.buyShares(marketId, true, 100);

        (uint256 aliceSharesA,) = predictionMarketEngine.getSharesBalance(marketId, alice);
        assertEq(aliceSharesA, 100);
        vm.stopPrank();

        vm.startPrank(bob);
        predictionMarketToken.approve(address(predictionMarketEngine), 100);
        predictionMarketEngine.buyShares(marketId, false, 100);

        (uint256 bobSharesA,) = predictionMarketEngine.getSharesBalance(marketId, bob);
        assertEq(bobSharesA, 0);
        vm.stopPrank();
    }

    function testResolveMarket() external {
        vm.prank(owner);
        uint256 marketId = predictionMarketEngine.createMarket("Who will win the election?", "Alice", "Bob", 100);

        vm.warp(block.timestamp + 100);

        vm.prank(owner);
        predictionMarketEngine.resolveMarket(marketId, PredictionMarketEngine.MarketOutcome.OPTION_A);

        (,,,,,,, PredictionMarketEngine.MarketOutcome marketOutcome) = predictionMarketEngine.getMarketInfo(marketId);
        assertEq(uint8(marketOutcome), uint8(PredictionMarketEngine.MarketOutcome.OPTION_A));
    }
}
