// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    constructor() {}

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMininumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner(), msg.sender);
        // Below doesn't work because the contract deployed FundMe. While WE are msg.sender, calling the test contract.
        // assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceAggregatorVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }
}
