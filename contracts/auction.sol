pragma solidity ^0.4.0;

contract SimpleAuction {
    address public beneficiary;
    uint public auctionStart;
    uint public biddingTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor (uint _biddingTime, address _beneficiary) public {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
    }

    function bid() public payable {
        require (now < auctionStart + biddingTime, 'The auction has ended.');
        require (msg.value > highestBid, 'The bid provided is lower than the highest one.');

        if (highestBidder != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool){
        uint amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.transfer(amount)) {
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

        require(beneficiary.transfer(highestBid), 'Error transfering founds to the beneficiary');
    }
}