// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
//Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// within function:
// payable
// non - payable
// view
// pure

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error PredictionMarketEngine_PredictionMarketTokenTransferFailed(address from, address to, uint256 amount);

contract PredictionMarketEngine is Ownable, ReentrancyGuard {
    enum MarketOutcome {
        UNRESOLVED,
        OPTION_A,
        OPTION_B
    }

    struct Market {
        uint256 endTime;
        string question;
        string optionA;
        string optionB;
        uint256 totalOptionAShares;
        uint256 totalOptionBShares;
        bool resolved;
        MarketOutcome outcome;
        mapping(address => uint256) userSharesA;
        mapping(address => uint256) userSharesB;
        mapping(address => bool) hasClaimed;
    }

    event MarketCreated(uint256 indexed marketId, string question, string optionA, string optionB, uint256 endTime);
    event MarketSharesPurchased(uint256 indexed marketId, address indexed user, bool isOptionA, uint256 amount);
    event MarketResolved(uint256 indexed marketId, MarketOutcome outcome);
    event MarketClaimed(uint256 indexed marketId, address indexed user, uint256 amount);

    IERC20 public predictionMarketToken;
    uint256 public marketCount;
    mapping(uint256 => Market) public markets;

    constructor(address initialOwner, address _predictionMarketToken) Ownable(initialOwner) {
        predictionMarketToken = IERC20(_predictionMarketToken);
    }

    function createMarket(string memory _question, string memory _optionA, string memory _optionB, uint256 _duration)
        external
        onlyOwner
        returns (uint256)
    {
        require(_duration > 0, "Duration must be greater than 0");
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(bytes(_optionA).length > 0 && bytes(_optionB).length > 0, "Options cannot be empty");

        uint256 marketId = marketCount++;
        Market storage market = markets[marketId];

        market.endTime = block.timestamp + _duration;
        market.question = _question;
        market.optionA = _optionA;
        market.optionB = _optionB;
        market.outcome = MarketOutcome.UNRESOLVED;

        emit MarketCreated(marketId, _question, _optionA, _optionB, market.endTime);

        return marketId;
    }

    function buyShares(uint256 _marketId, bool _isOptionA, uint256 _amount) external nonReentrant {
        Market storage market = markets[_marketId];
        require(block.timestamp < market.endTime, "Market has ended");
        require(!market.resolved, "Market has been resolved");
        require(_amount > 0, "Amount must be greater than 0");

        if (_isOptionA) {
            market.userSharesA[msg.sender] += _amount;
            market.totalOptionAShares += _amount;
        } else {
            market.userSharesB[msg.sender] += _amount;
            market.totalOptionBShares += _amount;
        }

        bool isSuccess = predictionMarketToken.transferFrom(msg.sender, address(this), _amount);

        if (!isSuccess) {
            revert PredictionMarketEngine_PredictionMarketTokenTransferFailed(msg.sender, address(this), _amount);
        }

        emit MarketSharesPurchased(_marketId, msg.sender, _isOptionA, _amount);
    }

    function resolveMarket(uint256 _marketId, MarketOutcome _marketOutcome) external onlyOwner {
        Market storage market = markets[_marketId];
        require(block.timestamp >= market.endTime, "Market has not ended yet");
        require(!market.resolved, "Market has already been resolved");
        require(_marketOutcome != MarketOutcome.UNRESOLVED, "Invalid outcome");

        market.outcome = _marketOutcome;
        market.resolved = true;

        emit MarketResolved(_marketId, _marketOutcome);
    }
}
