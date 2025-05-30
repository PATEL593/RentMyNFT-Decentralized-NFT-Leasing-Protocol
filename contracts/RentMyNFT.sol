// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RentMyNFT is IERC721Receiver, Ownable {
    struct Lease {
        address nftContract;
        uint256 tokenId;
        address owner;
        address renter;
        uint256 price;
        uint256 expiry;
        bool active;
    }

    uint256 public leaseCounter;
    mapping(uint256 => Lease) public leases;

    event NFTListed(uint256 leaseId, address owner, address nftContract, uint256 tokenId, uint256 price, uint256 expiry);
    event NFTRented(uint256 leaseId, address renter);
    event LeaseEnded(uint256 leaseId);

    constructor() Ownable(msg.sender) {}

    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    ) external {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        leases[leaseCounter] = Lease({
            nftContract: nftContract,
            tokenId: tokenId,
            owner: msg.sender,
            renter: address(0),
            price: price,
            expiry: block.timestamp + duration,
            active: true
        });

        emit NFTListed(leaseCounter, msg.sender, nftContract, tokenId, price, block.timestamp + duration);
        leaseCounter++;
    }

    function rentNFT(uint256 leaseId) external payable {
        Lease storage lease = leases[leaseId];
        require(lease.active, "Lease not active");
        require(lease.renter == address(0), "Already rented");
        require(msg.value == lease.price, "Incorrect payment");

        lease.renter = msg.sender;

        emit NFTRented(leaseId, msg.sender);
    }

    function endLease(uint256 leaseId) external {
        Lease storage lease = leases[leaseId];
        require(lease.active, "Already inactive");
        require(block.timestamp >= lease.expiry || msg.sender == lease.owner, "Not authorized or lease active");

        lease.active = false;
        IERC721(lease.nftContract).transferFrom(address(this), lease.owner, lease.tokenId);

        payable(lease.owner).transfer(lease.price);
        emit LeaseEnded(leaseId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}