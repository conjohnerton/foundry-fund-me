// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 private constant MINIMUM_USD = 5e18;
    address immutable USER = makeAddr("user");
    uint256 immutable USER_STARTING_BALANCE = 100e18;

    constructor() {}

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: MINIMUM_USD}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, USER_STARTING_BALANCE);
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

    function testFundFailsWithLessThanMinimum() public {
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund{value: 0}();
    }

    function testFundUpdatesFundMeDataStructures() public {
        vm.prank(USER);
        fundMe.fund{value: MINIMUM_USD}();

        assertEq(fundMe.getAddressToAmountFunded(USER), MINIMUM_USD);
    }

    function testAddsFunderToFundersArray() public funded {
        vm.prank(USER);
        fundMe.fund{value: MINIMUM_USD}();

        assertEq(fundMe.getFunder(0), USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.expectRevert();

        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawFromSingleFunder() public funded {
        uint256 startingBalance = fundMe.i_owner().balance;
        uint256 expectedBalance = startingBalance + address(fundMe).balance;

        vm.prank(fundMe.i_owner());
        fundMe.withdraw();

        assertEq(fundMe.i_owner().balance, expectedBalance);
        assertEq(address(fundMe).balance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFounders = 10;
        uint160 startingFounderIndex = 1;

        for (uint160 i = startingFounderIndex; i < numberOfFounders; i++) {
            hoax(address(i), MINIMUM_USD);
            fundMe.fund{value: MINIMUM_USD}();
        }

        uint256 startingBalance = fundMe.i_owner().balance;
        uint256 expectedBalance = startingBalance + address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(1);

        vm.startPrank(fundMe.i_owner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used by withdraw", gasUsed);

        assertEq(fundMe.i_owner().balance, expectedBalance);
        assertEq(address(fundMe).balance, 0);
    }
    
    function testCheapWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFounders = 10;
        uint160 startingFounderIndex = 1;

        for (uint160 i = startingFounderIndex; i < numberOfFounders; i++) {
            hoax(address(i), MINIMUM_USD);
            fundMe.fund{value: MINIMUM_USD}();
        }

        uint256 startingBalance = fundMe.i_owner().balance;
        uint256 expectedBalance = startingBalance + address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(1);

        vm.startPrank(fundMe.i_owner());
        fundMe.cheapWithdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used by withdraw", gasUsed);

        assertEq(fundMe.i_owner().balance, expectedBalance);
        assertEq(address(fundMe).balance, 0);
    }
}
