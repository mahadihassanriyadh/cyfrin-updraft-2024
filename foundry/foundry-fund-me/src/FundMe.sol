// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./lib/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// it's a convention to add the contract name before the error so that it's easier for us to understand where the error is coming from
error FundMe__DidNotSendMinEth();
error FundMe__NotFundOwner();
error FundMe__FundTransferFailed();
error FundMe__FallbackTriggerNotMatched();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MIN_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    address public immutable i_fundOwner;

    constructor(address priceFeed) {
        i_fundOwner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MIN_USD) {
            revert FundMe__DidNotSendMinEth();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIdx = 0; funderIdx < s_funders.length; funderIdx++) {
            address funder = s_funders[funderIdx];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!callSuccess) {
            revert FundMe__FundTransferFailed();
        }
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_fundOwner) {
            revert FundMe__NotFundOwner();
        }
        _;
    }

    // when someone sends ether to this contract directly without any data
    receive() external payable {
        fund();
    }

    // when someone sends ether to this contract directly with some data
    fallback() external payable {
        fund();
    }
}
