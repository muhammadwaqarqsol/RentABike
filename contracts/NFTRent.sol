// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC4907.sol";

contract MyToken is IERC4907, ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    mapping(uint256=>address) creatorNFT;

    mapping(uint256=>address) userofTokenID;

    mapping(uint256=>uint64) tokenExpires;

    mapping(address=>uint64) rentExpire;

    // mapping(uint256=>address) rentedNFT;

    function setUser(uint256 tokenId,address user,uint64 expires) public virtual  {
        require(_isApprovedOrOwner(msg.sender,tokenId),"ERC:721 Transfer is not A caller Nor Approved");
        userofTokenID[tokenId]=user;
        rentExpire[user]=expires;
        tokenExpires[tokenId]=expires;
        _transfer(creatorNFT[tokenId],user,tokenId);
    }

    function userOf(uint256 tokenId,address user) public view  virtual   returns(address){
        if(uint256(rentExpire[user])>=block.timestamp){
            return userofTokenID[tokenId];
        }else{
            return address(0);
        }
    }

    function userExpires(uint256 tokenId) public view virtual returns (uint256){
        return tokenExpires[tokenId];
    }


    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        creatorNFT[tokenId]=msg.sender;
    }

    function userOf(uint256 tokenId) external view returns (address){
        return userofTokenID[tokenId];
            }

    // function userExpires(address user) external view returns (uint256){
    //     return tokenidExpires[user];
    // }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
       require(msg.sender == owner(),"Only the contract owner can set the user");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721,ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    

    // // Override the transfer function
    // function transfer(address to, uint256 tokenId) public override {
    // require(msg.sender == creatorNFT[tokenId], "You are not the owner of this NFT");
    // // Transfer the NFT to the new owner
    // super.transfer(to, tokenId);
    // }

    // // Override the safeTransfer function
    // function safeTransfer(address to, uint256 tokenId, bytes memory data) public override {
    //  require(msg.sender == creatorNFT[tokenId], "You are not the owner of this NFT");

    // // Transfer the NFT to the new owner
    // super.safeTransfer(to, tokenId, data);
    // }

    // // Override the safeTransferFrom function
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    //  require(msg.sender == creatorNFT[tokenId], "You are not the owner of this NFT");
    // // Transfer the NFT to the new owner
    // super.safeTransferFrom(from, to, tokenId, data);

    // }
}
