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
    uint private counter;
    IERC20 private paymentToken;
    address private safe;// address to withdraw earnings

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
        price[tokenId] = newPrice;
    }
    function buy(uint tokenId) external { // make direct purchase
        require(price[tokenId] > 0, "NFT not for sale");
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
}
