// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {Test, console} from "forge-std/Test.sol";
import {DutchAuction} from "../src/DutchAuction.sol";


contract DutchAutionTest is Test {
    DutchAuction dutchAuction;
    uint256  startingPrice = 10 ether;
    uint256  discountRate = 0.001 ether;
    uint256  expiresAt = 3600; //1 hr = 3600 secs
    string  auctionItem = "Borderless";
    address payable seller;
    address tester;
    
    function setUp() public {
        seller = payable(address(this));
        dutchAuction = new DutchAuction(startingPrice, discountRate, expiresAt, auctionItem);
    }

    function testStartingPriceTooLow() public{
        uint256 testStartingPrice = 1 ether;

        vm.expectRevert("Starting price too low for this discount rate and duration");
        new DutchAuction(testStartingPrice, discountRate, expiresAt, auctionItem);
    }

    function testGetPriceAfterTimeElapsed() public{
       // uint256 remainingAmount = startingPrice - (discountRate * expiresAt);
        vm.prank(tester);
        vm.warp(block.timestamp + expiresAt);
        uint256 actualRemainingamount = dutchAuction.getPrice();

        assertEq(actualRemainingamount, 0);


    }   
    
    function testGetPriceBeforeTimeElapsed() public{
        uint256 remainingAmount = startingPrice - (discountRate * 2000);
        vm.prank(tester);
        vm.warp(block.timestamp + 2000);
        uint256 actualRemainingamount = dutchAuction.getPrice();

        assertEq(actualRemainingamount, remainingAmount);

    }

    function testFuzzGetPriceBeforeTimeElapsed(uint256 duration) public{
        vm.assume(duration < 3600 && duration > 0);
        uint256 remainingAmount = startingPrice - (discountRate * duration);
        vm.prank(tester);
        vm.warp(block.timestamp + duration);
        uint256 actualRemainingamount = dutchAuction.getPrice();

        assertEq(actualRemainingamount, remainingAmount);

    }

    function testBuyWhenTimeElapsed() public {
        vm.warp(block.timestamp + expiresAt);
        uint256 accountBalance = 30 ether;
        vm.deal(tester, accountBalance);


        vm.expectRevert("Auction has already ended");


        vm.prank(tester);
        dutchAuction.buy{value: accountBalance}();
    }     

    function testFuzzBuyAfterTimeElapsed(uint duration) public {
        vm.assume(duration > 3600 && duration < 86400); //duration must be after an hour but before 24 hours
        vm.warp(block.timestamp + duration);
        uint256 accountBalance = 30 ether;
        vm.deal(tester, accountBalance);


        vm.expectRevert("Auction has already ended");


        vm.prank(tester);
        dutchAuction.buy{value: accountBalance}();
    } 

    function testBuyBeforeTimeElapsed() public {
        vm.warp(block.timestamp + 1800);
        vm.deal(tester, startingPrice);

        uint256 expectedPrice = dutchAuction.getPrice();
        vm.prank(tester);
        dutchAuction.buy{value: expectedPrice}();

// Check that the item is marked as sold
        assertTrue(dutchAuction.sold());


    }    
    
    function testFuzzBuyBeforeTimeElapsed(uint256 duration) public {
        vm.assume(duration < 3600 && duration > 0);
        vm.warp(block.timestamp + duration);
        vm.deal(tester, startingPrice);

        uint256 expectedPrice = dutchAuction.getPrice();
        vm.prank(tester);
        dutchAuction.buy{value: expectedPrice}();

// Check that the item is marked as sold
        assertTrue(dutchAuction.sold());


    }

    function testInsufficientFunds() public {
        uint256 enteringPrice = 0.5 ether;

        vm.warp(block.timestamp + 1800);
        vm.deal(tester, startingPrice);


        vm.expectRevert("Insufficient funds to buy item");

         vm.prank(tester);
        dutchAuction.buy{value: enteringPrice}();

    }

    function testIsSold() public {
        dutchAuction.setSold(true);
        vm.deal(tester, startingPrice);

        vm.expectRevert("Item has already been sold");

        vm.prank(tester);
        dutchAuction.buy{value: startingPrice}();



    }

    receive() external payable {}
}