// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {Script, console} from "forge-std/Script.sol";
import {DutchAuction} from "../src/DutchAuction.sol";

contract AuctionDeployer is Script{
    DutchAuction dutchAuction;
    function run() external returns(DutchAuction) {
        uint256  startingPrice = 10 ether;
        uint256  discountRate = 0.001 ether;
        uint256  expiresAt = 3600; //1 hr = 3600 secs
        string memory auctionItem = "Borderless";

        vm.startBroadcast();
            dutchAuction = new DutchAuction(startingPrice, discountRate, expiresAt, auctionItem);
        
        vm.stopBroadcast();
        return dutchAuction;
    
    }
}