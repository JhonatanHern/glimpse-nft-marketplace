//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * This contract adds three different ways to exchange tokens
 * 1 - Auction
 * 2 - Offer that can be accepted by the owner
 * 3 - Direct purchase for a set price
*/

contract Marketplace is ERC721{
    using SafeERC20 for IERC20;

    mapping(uint => string) public fileHash;// ipfs hash
    mapping(uint => uint) public authorComissionPercent;// percent of auction that goes to the author
    mapping(uint => address) public author;// this separates the author from the owner for commission purposes
    mapping(uint => uint) public price;// price for direct purchase
    mapping(string => bool) hashExists;
    uint private taxRate;// tax = price / taxRate
    uint private earnings;// GLMS earnings from taxes go here 
    uint private counter;
    IERC20 private paymentToken;
    address private safe;// address to withdraw earnings

    struct Auction {
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
        uint256 duration;
    }
    struct Offer {
        bool bought;
        bool cancelled;
        uint256 offerAmount;
        address buyer;
    }

    mapping(uint256 => Auction) public tokenIdToAuction;
    mapping(uint => Offer[]) public offersPerNFT;

    event OfferMade(uint256 tokenId, uint256 amount);

    constructor(address _paymentToken, uint _taxRate, address _safe) ERC721("Glimpse", "GLMS"){
        paymentToken = IERC20(_paymentToken);
        taxRate = _taxRate;
        safe = _safe;
    }

    function mint(string calldata _videoHash, uint _authorComissionPercent) external returns(uint) {
        require(!hashExists[_videoHash], "file already registered");
        require(_authorComissionPercent <= 10, "Author comission cannot excede 5%");
        fileHash[counter] = _videoHash;
        authorComissionPercent[counter] = _authorComissionPercent;
        author[counter] = msg.sender;
        hashExists[_videoHash] = true;
        _mint(msg.sender, counter);
        counter++;
        return counter - 1;
    }
    function mintTo(string calldata _videoHash, uint _authorComissionPercent, address _to) external returns(uint) {
        require(!hashExists[_videoHash], "file already registered");
        require(_authorComissionPercent <= 10, "Author comission cannot excede 5%");
        fileHash[counter] = _videoHash;
        authorComissionPercent[counter] = _authorComissionPercent;
        author[counter] = msg.sender;
        hashExists[_videoHash] = true;
        _mint(_to, counter);
        counter++;
        return counter - 1;
    }
    function setPrice(uint tokenId, uint newPrice) external { // set price for direct purchase
        require(msg.sender == ownerOf(tokenId), "Must be owner to set price");
        require(tokenIdToAuction[tokenId].seller == address(0), "can't set price during an auction");
        price[tokenId] = newPrice;
    }
    function buy(uint tokenId) external { // make direct purchase
        require(price[tokenId] > 0, "NFT not for sale");
        require(tokenIdToAuction[tokenId].seller == address(0), "can't make direct purchase during an auction");
        uint tax = price[tokenId] / taxRate;
        address owner = ownerOf(tokenId);
        if (author[tokenId] == owner) {
            paymentToken.safeTransferFrom(msg.sender, owner, price[tokenId] - tax);
        } else {
            uint authorComission = price[tokenId] * authorComissionPercent[tokenId] / 100;
            paymentToken.safeTransferFrom(msg.sender, owner, price[tokenId] - tax - authorComission);
            paymentToken.safeTransferFrom(msg.sender, author[tokenId], authorComission);
        }
        price[tokenId] = 0;
        paymentToken.safeTransferFrom(msg.sender, safe, tax);
        _transfer(owner, msg.sender, tokenId);
    }
    function makeOffer(uint256 tokenId, uint256 amount) external {
        Offer memory o = Offer(
            false, // bought
            false, // cancelled
            amount, // offerAmount
            msg.sender // buyer
        );
        offersPerNFT[tokenId].push(o);
        emit OfferMade(tokenId, amount);
    }
    function acceptOffer(uint tokenId, uint offerIndex) external{ // only NFT owner
        require(msg.sender == ownerOf(tokenId), "You must be the owner to accept an offer");
        require(tokenIdToAuction[tokenId].seller == address(0), "can't accept offer during an auction");
        Offer storage offerToAccept = offersPerNFT[tokenId][offerIndex];
        require(!offerToAccept.bought, "offer must not have been already accepted");
        require(!offerToAccept.cancelled, "offer must not have been cancelled");
        offerToAccept.bought = true;
        uint tax = offerToAccept.offerAmount / taxRate;
        if (author[tokenId] == msg.sender) {
            paymentToken.safeTransferFrom(offerToAccept.buyer, msg.sender, offerToAccept.offerAmount - tax);
        } else {
            uint authorComission = offerToAccept.offerAmount * authorComissionPercent[tokenId] / 100;
            paymentToken.safeTransferFrom(offerToAccept.buyer, msg.sender, offerToAccept.offerAmount - tax - authorComission);
            paymentToken.safeTransferFrom(offerToAccept.buyer, author[tokenId], authorComission);
        }
        _transfer(msg.sender, offerToAccept.buyer, tokenId);
        paymentToken.safeTransferFrom(offerToAccept.buyer, safe, tax);
        price[tokenId] = 0;
    }
    function cancelOffer(uint tokenId, uint offerIndex) external{ // only buyer
        Offer storage offerToReject = offersPerNFT[tokenId][offerIndex];
        require(!offerToReject.cancelled, "offer must not have been cancelled already");
        offerToReject.cancelled = true;
    }
    function getOffers(uint tokenId) external view returns(Offer [] memory){
        return offersPerNFT[tokenId];
    }
    function createAuction(uint256 _tokenId, uint128 _startingPrice, uint256 _duration) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Marketplace: auction caller is not owner nor approved");
        address owner = ownerOf(_tokenId);
        _transfer(owner, address(this), _tokenId);
        Auction memory _auction = Auction({
            seller: owner,
            highestBid: uint128(_startingPrice),
            startTime: block.timestamp,
            highestBidder: address(0),
            duration: _duration
        });
        tokenIdToAuction[_tokenId] = _auction;
        price[_tokenId] = 0; // direct purchase is forbidden during an auction
    }
    function bid(uint256 _tokenId, uint256 amount) external {
        require(amount > tokenIdToAuction[_tokenId].highestBid );
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        if (tokenIdToAuction[_tokenId].highestBidder != address(0)) {
            paymentToken.safeTransfer(tokenIdToAuction[_tokenId].highestBidder, tokenIdToAuction[_tokenId].highestBid);
        }
        tokenIdToAuction[_tokenId].highestBidder = msg.sender;
        tokenIdToAuction[_tokenId].highestBid = amount;
    }
    function cancelAuction(uint256 _tokenId) external {
        require(tokenIdToAuction[_tokenId].seller == msg.sender, "Marketplace: only owner can cancel auction");
        require(tokenIdToAuction[_tokenId].highestBidder == address(0), "can't cancel if there's a bid");
        _transfer(address(this), msg.sender, _tokenId);
        delete tokenIdToAuction[_tokenId];
    }
    function claimWinningBid(uint _tokenId) external{
        require(tokenIdToAuction[_tokenId].highestBidder == msg.sender, "Marketplace: Only winner can claim");
        require(block.timestamp > tokenIdToAuction[_tokenId].startTime + tokenIdToAuction[_tokenId].duration, "Marketplace: Auction time must pass");
        _transfer(address(this), msg.sender, _tokenId);
        uint tax;
        if(tokenIdToAuction[_tokenId].seller == author[_tokenId]){
            tax = tokenIdToAuction[_tokenId].highestBid / taxRate;
            paymentToken.safeTransfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid - tax
            );
        }else{
            uint authorComission = tokenIdToAuction[_tokenId].highestBid * authorComissionPercent[_tokenId] / 100;
            tax = (tokenIdToAuction[_tokenId].highestBid - authorComission) / taxRate;
            paymentToken.safeTransfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid - authorComission - tax
            );
            paymentToken.safeTransfer(
                author[_tokenId],
                authorComission
            );
        }
        earnings = earnings + tax;
        delete tokenIdToAuction[_tokenId];
        price[_tokenId] = 0;
    }
    function withdraw() external {
        paymentToken.safeTransfer(
            safe,
            earnings
        );
        earnings = 0;
    }
}
