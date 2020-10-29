pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;
    uint public auctionStart;
    uint public biddingTime;

    address payable public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;
    address payable[] pendingAccounts;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor (
        uint _biddingTime, 
        address payable _beneficiary 
    ) public {
        auctionStart = now;
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
    }

    function bid() public payable {
        require (now < auctionStart + biddingTime, "The auction has ended.");
        require (msg.value > highestBid, "The bid provided is lower than the highest one.");
        require (msg.sender != highestBidder, "You are already the highest bidder.");

//        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
            pendingAccounts.push(highestBidder);
//        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            //if (!msg.sender.send(amount)) {
            (bool success, ) = msg.sender.call.value(amount)("");
            if (!success) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    function auctionEnd() public {
        require (now < auctionStart + biddingTime, "The auction is already finished.");
        require (!ended, "The auction is already finished");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // require (beneficiary.send(highestBid), "Error transfering founds to the beneficiary");
        (bool success, ) = beneficiary.call.value(highestBid)("");
        require (success, "Error transfering founds to the beneficiary");
    }

}
