//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Marketplace is ERC721{
    using SafeERC20 for IERC20;

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
    struct Offer {
        bool bought;
        bool cancelled;
        uint256 offerAmount;
        address buyer;
    }

    mapping(uint256 => Auction) public tokenIdToAuction;
    mapping(uint => Offer[]) public offersPerNFT;

    event OfferMade(uint256 tokenId, uint256 amount);

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
    function offer(uint256 tokenId, uint256 amount) external {
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
        require(msg.sender == ownerOf(tokenId));
        Offer storage offerToAccept = offersPerNFT[tokenId][offerIndex];
        require(!offerToAccept.bought, "offer must not have been already accepted");
        require(!offerToAccept.cancelled, "offer must not have been cancelled");
        offerToAccept.bought = true;
        paymentToken.safeTransferFrom(offerToAccept.buyer, msg.sender, offerToAccept.offerAmount);
        _transfer(msg.sender, offerToAccept.buyer, tokenId);

    }
    function cancelOffer(uint tokenId, uint offerIndex) external{ // only buyer
        Offer storage offerToReject = offersPerNFT[tokenId][offerIndex];
        require(!offerToReject.cancelled, "offer must not have been cancelled already");
        offerToReject.cancelled = true;
    }
    function getOffers(uint tokenId) external view returns(Offer [] memory){
        return offersPerNFT[tokenId];
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
        require(block.timestamp > tokenIdToAuction[_tokenId].startTime + 24 hours, "Marketplace: Auction time must pass");
        _transfer(address(this), msg.sender, _tokenId);
        if(tokenIdToAuction[_tokenId].seller == author[_tokenId]){
            paymentToken.safeTransfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid
            );
        }else{
            uint authorComission = tokenIdToAuction[_tokenId].highestBid * 100 / authorComissionPercent[_tokenId];
            paymentToken.safeTransfer(
                tokenIdToAuction[_tokenId].seller,
                tokenIdToAuction[_tokenId].highestBid - authorComission
            );
            paymentToken.safeTransfer(
                author[_tokenId],
                authorComission
            );
        }
        delete tokenIdToAuction[_tokenId];
    }
}
