// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DutchAuction {
    uint256 private startingPrice;
    uint256 private discountRate;
    uint256 private startAt;
    uint256 private expiresAt;
    address payable immutable public seller;
    string private auctionItem;
    bool public sold;

    event AuctionEnded(address buyer, uint256 amount);
    event Refund(address buyer, uint256 amount);


    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        uint256 _duration,
        string memory _auctionItem
    ){
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + _duration;
        auctionItem = _auctionItem;
        sold= false;

        require(_startingPrice >= _discountRate * _duration, "Starting price too low for this discount rate and duration");

    }

     modifier onlyOwner() {
        require(msg.sender == seller, "Only Owner can authorize");
        _;
    }

    function getPrice() public view returns (uint256) {
        if(block.timestamp >= expiresAt){
            return 0;
        }
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "Auction has already ended");
        require(msg.value >= getPrice(), "Insufficient funds to buy item");
        require(!sold, "Item has already been sold");

        // (bool success,) = seller.call{value: msg.value}('');
        // require(success, "Transfer failed");

        uint256 refund = msg.value - getPrice();

        if(refund > 0){
            payable(msg.sender).transfer(refund);
            emit Refund(msg.sender, refund);
        }

        uint256 purchaseAmount = msg.value - refund;

        seller.transfer(purchaseAmount);

        sold = true;
        emit AuctionEnded(msg.sender, purchaseAmount);


       
    }

    function setSold(bool _sold) external onlyOwner{
        sold = _sold;
    }


}