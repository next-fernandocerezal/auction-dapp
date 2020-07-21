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

    public function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
    }

    public function bid() payable {
        if (now > auctionStart + biddingTime) throw;
        if (msg.value <= highestBid) throw;

        if (highestBidder != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }

    public function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    public function auctionEnd() {
        if (now <= auctionStart + biddingTime) throw;
        if (ended) throw;

        ended = true;
        AuctionEnded(highestBidder, highestBid);

        if (!beneficiary.send(highestBid)) throw;
    }
}