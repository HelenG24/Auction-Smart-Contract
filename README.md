# Auction-Smart-Contract

This smart contract implements a transparent and secure auction system on the Ethereum blockchain. Key features include:

- Time-based auction with automatic extension
- Minimum bid increment of 5%
- 2% commission on the winning bid
- Partial refunds during the auction
- Secure fund handling

Functions

1. Constructor
Initializes the auction with a specified duration
Sets the contract owner to the deployer

2. bid()
Allows participants to place bids
Requires bids to be at least 5% higher than the current highest
Automatically extends auction if bid is placed in last 10 minutes

3. withdrawOverbid()
Allows non-winning bidders to withdraw their funds during the auction

4. endAuction()
Can only be called by owner after auction ends
Distributes funds (2% to owner, rest to winner)
Refunds all other bidders

5. View Functions
getBidders(): Returns all bidders and their amounts
getWinner(): Returns the current highest bidder and amount
getRemainingTime(): Returns time left in auction

Events
- NewBid: Emitted when a new valid bid is placed
- AuctionExtended: Emitted when the auction is extended
- AuctionEnded: Emitted when the auction concludes
- Refund: Emitted when a bidder receives a refund

Security Features
- Protection against reentrancy attacks
- Proper access control with modifiers
- Prevention of accidental ETH transfers
- Comprehensive input validation

The contract has been designed to be robust and handle all edge cases while providing transparency to all participants through emitted events.
