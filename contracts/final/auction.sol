pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;
    address public admin;
    uint public auctionStart;
    uint public biddingTime;
    uint public numberOfBids;

    address payable public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;
    address payable[] pendingAccounts;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount, numberOfBids);
    event AuctionEnded(address winner, uint amount);
    event AuctionCanceled();

    

    constructor (
        uint _biddingTime, 
        address payable _beneficiary, 
        address payable _admin
    ) public {
        auctionStart = now;
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
        admin = _admin;
        numberOfBids=0;
    }

    function bid() public payable {
        require (now < auctionStart + biddingTime, "The auction has ended.");
        require (msg.value > highestBid, "The bid provided is lower than the highest one.");
        require (msg.sender != highestBidder, "You are already the highest bidder.");
        require (msg.sender != admin, "The auction admin can't place a bid." );

//        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
            pendingAccounts.push(highestBidder);
//        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        numberOfBids++;
        emit HighestBidIncreased(msg.sender, msg.value, numberOfBids);
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
        numberOfBids--;
        return true;
    }

    function auctionEnd() public {
        require (now < auctionStart + biddingTime, "The auction is already finished.");
        require (msg.sender == admin, "You don't have permission to cancel the auction.");
        require (!ended, "The auction is already finished");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // require (beneficiary.send(highestBid), "Error transfering founds to the beneficiary");
        (bool success, ) = beneficiary.call.value(highestBid)("");
        require (success, "Error transfering founds to the beneficiary");
    }

    function auctionCancel() public {
        require (msg.sender == admin, "You don't have permission to cancel the auction.");

        ended = true;
        emit AuctionCanceled();

        for (uint i = 0; i < pendingAccounts.length; i++) {
            address payable bidder = pendingAccounts[i];
            uint amount = pendingReturns[bidder];

            // require (bidder.send(amount), "Error placing pending returns");
            (bool success, ) = bidder.call.value(amount)("");
            require (success, "Error placing pending returns");
        }

        // require (highestBidder.send(highestBid), "Error placing pending returns");
        (bool success, ) = highestBidder.call.value(highestBid)("");
        require (success, "Error placing pending returns");
    }
}
