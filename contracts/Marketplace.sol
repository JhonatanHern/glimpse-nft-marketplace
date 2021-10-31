//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace is ERC721{
    mapping(uint => string) public fileHash;// ipfs hash
    mapping(uint => uint) public authorComissionPercent;// percent of auction that goes to the author
    mapping(uint => address) public author;// this separates the author from the owner for commission purposes
    mapping(string => bool) hashExists;
    uint private counter;
    IERC20 private paymentToken;

    struct Auction {
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
    }

    mapping(uint256 => Auction) public tokenIdToAuction;

    constructor(address _paymentToken) ERC721("Glimpse", "GLMS"){
        paymentToken = IERC20(_paymentToken);
    }

    function mint(string calldata _videoHash, uint _authorComissionPercent) external returns(uint) {
        require(!hashExists[_videoHash], "file already registered");
        fileHash[counter] = _videoHash;
        authorComissionPercent[counter] = _authorComissionPercent;
        author[counter] = msg.sender;
        hashExists[_videoHash] = true;
        _mint(msg.sender, counter);
        counter++;
        return counter - 1;
    }

    function createAuction(uint256 _tokenId, uint128 _startingPrice) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Marketplace: auction caller is not owner nor approved");
        address owner = ownerOf(_tokenId);
        _transfer(owner, address(this), _tokenId);
        Auction memory _auction = Auction({
            seller: owner,
            highestBid: uint128(_startingPrice),
            startTime: block.timestamp,
            highestBidder: address(0)
        });
        tokenIdToAuction[_tokenId] = _auction;
    }
    function bid(uint256 _tokenId, uint256 amount) external {
        require(amount > tokenIdToAuction[_tokenId].highestBid );
        paymentToken.transferFrom(msg.sender, address(this), amount);
        if (tokenIdToAuction[_tokenId].highestBidder != address(0)) {
            paymentToken.transfer(tokenIdToAuction[_tokenId].highestBidder, tokenIdToAuction[_tokenId].highestBid);
        }
        tokenIdToAuction[_tokenId].highestBidder = msg.sender;
        tokenIdToAuction[_tokenId].highestBid = amount;
    }
    function cancelAuction(uint256 _tokenId) external {
        require(tokenIdToAuction[_tokenId].seller == msg.sender, "Marketplace: only owner can cancel auction");
        _transfer(address(this), msg.sender, _tokenId);
        if (tokenIdToAuction[_tokenId].highestBidder != address(0)) {
            paymentToken.transfer(
                tokenIdToAuction[_tokenId].highestBidder,
                tokenIdToAuction[_tokenId].highestBid
                );
        }
        delete tokenIdToAuction[_tokenId];
    }
    function claimWinningBid(uint _tokenId) external{
        require(tokenIdToAuction[_tokenId].highestBidder == msg.sender, "Marketplace: Only winner can claim");
        require(block.timestamp > tokenIdToAuction[_tokenId].startTime + 24 hours, "Marketplace: Auction time must pass");
        _transfer(address(this), msg.sender, _tokenId);
        if(tokenIdToAuction[_tokenId].seller == author[_tokenId]){
            paymentToken.transfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid
            );
        }else{
            uint authorComission = tokenIdToAuction[_tokenId].highestBid * 100 / authorComissionPercent[_tokenId];
            paymentToken.transfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid - authorComission
            );
            paymentToken.transfer(
                author[_tokenId],
                authorComission
            );
        }
        delete tokenIdToAuction[_tokenId];
    }
}
