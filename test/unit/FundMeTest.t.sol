//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe newFundMeContract;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //newFundMeContract = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        newFundMeContract = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        newFundMeContract.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public {
        assertEq(newFundMeContract.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(newFundMeContract.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = newFundMeContract.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithouthEnoughEth() public {
        vm.expectRevert();
        newFundMeContract.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = newFundMeContract.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        newFundMeContract.fund{value: SEND_VALUE}();
        address funder = newFundMeContract.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        newFundMeContract.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = newFundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMeContract).balance;

        // Act
        vm.prank(newFundMeContract.getOwner());
        newFundMeContract.withdraw();

        // Assert
        uint256 endingOwnerBalance = newFundMeContract.getOwner().balance;
        uint256 endingFundMeBalance = address(newFundMeContract).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            newFundMeContract.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = newFundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMeContract).balance;

        vm.startPrank(newFundMeContract.getOwner());
        newFundMeContract.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(newFundMeContract).balance == 0);
        assert(
            newFundMeContract.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            newFundMeContract.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = newFundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMeContract).balance;

        vm.startPrank(newFundMeContract.getOwner());
        newFundMeContract.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(newFundMeContract).balance == 0);
        assert(
            newFundMeContract.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }
}
