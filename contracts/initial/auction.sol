pragma solidity ^0.5.0;

//TODO

// add admin user
// add auction start and final time
// add security method to cancel bid

contract Auction {
    address payable public beneficiary;

    address payable public highestBidder;//user identified by address
    uint public highestBid;// quantity bidded

    mapping(address => uint) pendingReturns;//all biders, mapped address and quantities
    address payable[] pendingAccounts;//por qué payable en pendingAccounts? el admin cobra?


    event HighestBidIncreased(address bidder, uint amount);

    constructor (
        address payable _beneficiary, 
        //address payable _admin
    ) public {
        beneficiary = _beneficiary;
    }

    function bid() public payable {
        require (msg.value > highestBid, "The bid provided is lower than the highest one.");
        require (msg.sender != highestBidder, "You are already the highest bidder.");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
            pendingAccounts.push(highestBidder);
        }

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


}
