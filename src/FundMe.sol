// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address public immutable i_priceFeedAddress;

    constructor(address _priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeedAddress = _priceFeedAddress;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(AggregatorV3Interface(i_priceFeedAddress)) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(i_priceFeedAddress);
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Getters
    function getAddressToAmountFunded(address _address) public view returns (uint256) {
        return s_addressToAmountFunded[_address];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
