// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

contract Auction {
    address public owner;
    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;
    uint public minBidIncrement = 5; // 5%
    uint public commissionRate = 2; // 2%
    uint public extensionTime = 10 minutes;
    uint public minExtensionThreshold = 10 minutes;
    
    bool public auctionEnded = false;
    
    mapping(address => uint) public bids;
    address[] public bidders;
    
    event NewBid(address indexed bidder, uint amount);
    event AuctionExtended(uint newEndTime);
    event AuctionEnded(address indexed winner, uint amount);
    event Refund(address indexed bidder, uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(!auctionEnded, "Auction has been terminated");
        _;
    }
    
    modifier auctionEndedOnly() {
        require(block.timestamp >= auctionEndTime || auctionEnded, "Auction is still active");
        _;
    }
    
    constructor(uint _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    function bid() external payable auctionActive {
        uint newBid = bids[msg.sender] + msg.value;
        require(newBid > highestBid * (100 + minBidIncrement) / 100, "Bid must be at least 5% higher than current highest");
        
        // Add to bidders list if this is their first bid
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        bids[msg.sender] = newBid;
        
        // Update highest bidder if needed
        if (newBid > highestBid) {
            highestBidder = msg.sender;
            highestBid = newBid;
            
            // Extend auction if bid is placed within last 10 minutes
            if (auctionEndTime - block.timestamp < minExtensionThreshold) {
                auctionEndTime += extensionTime;
                emit AuctionExtended(auctionEndTime);
            }
        }
        
        emit NewBid(msg.sender, newBid);
    }
    
    function withdrawOverbid() external auctionActive {
        uint amount = bids[msg.sender];
        require(amount > 0, "No bids to withdraw");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        
        uint refundAmount = amount;
        bids[msg.sender] = 0;
        
        // If this bidder was in the bidders array, remove them
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] == msg.sender) {
                bidders[i] = bidders[bidders.length - 1];
                bidders.pop();
                break;
            }
        }
        
        payable(msg.sender).transfer(refundAmount);
        emit Refund(msg.sender, refundAmount);
    }
    
    function endAuction() external onlyOwner auctionEndedOnly {
        require(!auctionEnded, "Auction already ended");
        
        auctionEnded = true;
        
        // Calculate commission
        uint commission = highestBid * commissionRate / 100;
        uint winnerAmount = highestBid - commission;
        
        // Transfer commission to owner and winnings to highest bidder
        payable(owner).transfer(commission);
        payable(highestBidder).transfer(winnerAmount);
        
        // Refund all other bidders
        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            if (bidder != highestBidder && bids[bidder] > 0) {
                uint refundAmount = bids[bidder];
                bids[bidder] = 0;
                payable(bidder).transfer(refundAmount);
                emit Refund(bidder, refundAmount);
            }
        }
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    function getBidders() external view returns (address[] memory, uint[] memory) {
        uint[] memory amounts = new uint[](bidders.length);
        for (uint i = 0; i < bidders.length; i++) {
            amounts[i] = bids[bidders[i]];
        }
        return (bidders, amounts);
    }
    
    function getWinner() external view returns (address, uint) {
        return (highestBidder, highestBid);
    }
    
    function getRemainingTime() external view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }
    
    // Fallback function to prevent accidental ETH transfers
    fallback() external payable {
        revert("Please use the bid() function to participate in the auction");
    }
    
    receive() external payable {
        revert("Please use the bid() function to participate in the auction");
    }
}