pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;
    address payable public admin;
    uint public auctionStart;
    uint public biddingTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor (
        uint _biddingTime, 
        address payable _beneficiary, 
        address payable _admin
    ) public {
        auctionStart = now;
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
        admin = _admin;
    }

    function bid() public payable {
        require (now < auctionStart + biddingTime, 'The auction has ended.');
        require (msg.value > highestBid, 'The bid provided is lower than the highest one.');

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    function auctionEnd() public {
        require (now > auctionStart + biddingTime, 'The auction is already expired.');
        require (!ended, 'The auction is already ended.');

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        require (beneficiary.send(highestBid), 'Error transfering founds to the beneficiary');
    }
}