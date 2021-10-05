//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TokenAuction {
    ERC721 public nftContract;

    struct Auction {
        address seller;
        uint128 price;
    }

    mapping(uint256 => Auction) public tokenIdToAuction;

    constructor(address _nftAddress) public {
        nftContract = ERC721(_nftAddress);
    }

    function createAuction(uint256 _tokenId, uint128 _price) public {
        nftContract.takeOwnership(_tokenId);
        Auction memory _auction = Auction({
            seller: msg.sender,
            price: uint128(_price)
        });
        tokenIdToAuction[_tokenId] = _auction;
    }

    function bid(uint256 _tokenId) public payable {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(auction.seller != address(0));
        require(msg.value >= auction.price);

        address seller = auction.seller;
        uint128 price = auction.price;

        delete tokenIdToAuction[_tokenId];

        seller.transfer(price);
        nftContract.transfer(msg.sender, _tokenId);
    }

    function cancel(uint256 _tokenId) public {
        Auction memory auction = tokenIdToAuction[_tokenId];
        require(auction.seller == msg.sender);

        delete tokenIdToAuction[_tokenId];

        nftContract.transfer(msg.sender, _tokenId);
    }
}
