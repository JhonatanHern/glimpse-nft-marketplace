//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Marketplace is ERC721{
    mapping(uint => string) urls;
    uint private counter;

    constructor() ERC721("Glimpse", "GLMS"){
    }
    function mint(string calldata videoHash) external returns(uint index) {
        index = counter;
        urls[index] = videoHash;
        _mint(msg.sender, index);
        counter++;
    }
    function takeOwnership(uint _tokenId) external {
        
    }
}
