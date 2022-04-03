//SPDX-License-Identifier: UNLICENSED
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
    address private masterWallet; //wallet that pay fees
    
    modifier onlyMasterWallet(){
      require(msg.sender == masterWallet, "you do not have the permission to do that!");
      _;
    } 

    constructor(address _paymentToken, uint _taxRate, address _safe,address _masterWallet) ERC721("Glimpse", "GLMS"){
        paymentToken = IERC20(_paymentToken);
        taxRate = _taxRate;
        safe = _safe;
        masterWallet = _masterWallet;
    }

    function setMasterWallet(address _masterWallet) external onlyMasterWallet{
      masterWallet = _masterWallet;
    }


    function masterMint(string calldata _videoHash, uint _authorComissionPercent, address sender) external onlyMasterWallet returns(uint) {
        require(!hashExists[_videoHash], "file already registered");
        require(_authorComissionPercent <= 10, "Author comission cannot excede 10%");
        fileHash[counter] = _videoHash;
        authorComissionPercent[counter] = _authorComissionPercent;
        author[counter] = sender;
        hashExists[_videoHash] = true;
        _mint(sender, counter);
        counter++;
        return counter - 1;
    }

    function masterSetPrice(uint tokenId, uint newPrice, address sender) external onlyMasterWallet { // set price for direct purchase
        require(sender == ownerOf(tokenId), "Must be owner to set price");
        price[tokenId] = newPrice;
    }

    function masterBuy(uint tokenId, address sender) external onlyMasterWallet { // make direct purchase
        require(price[tokenId] > 0, "NFT not for sale");
        uint tax = price[tokenId] / taxRate;
        address owner = ownerOf(tokenId);
        if (author[tokenId] == owner) {
            paymentToken.safeTransferFrom(sender, owner, price[tokenId] - tax);
        } else {
            uint authorComission = price[tokenId] * authorComissionPercent[tokenId] / 100;
            paymentToken.safeTransferFrom(sender, owner, price[tokenId] - tax - authorComission);
            paymentToken.safeTransferFrom(sender, author[tokenId], authorComission);
        }
        price[tokenId] = 0;
        paymentToken.safeTransferFrom(sender, safe, tax);
        _transfer(owner, sender, tokenId);
    }
    function tokenURI(uint256 _tokenId) public view override virtual returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(
            abi.encodePacked(
                "ipfs://" ,
                fileHash[_tokenId]
            )
        );
    }
}
