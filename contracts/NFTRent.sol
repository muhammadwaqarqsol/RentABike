// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rentabike is  ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    // uint public chargeRate =500000000000000000;
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK")
    {

    }
    
    //chargeRate mapping for different Bikes
    mapping(uint256=>uint256) public chargeRate;

    //Mapping for keeping userride active when rented otherwise false
    mapping(address=>bool) public activeRide;

    //Mapping to track startingTime for a ride
    mapping(address=>uint) public startTime;

    //mapping to keep track of rentedbikes
    mapping (uint256=>address) public rentedNFT;

    //Mapping to keep track of Listed Bikes for Rent
    mapping(uint256=>bool) public nftListed;

    //mapping to sell bike
    mapping(uint256=>uint256) public bikePrice;

    //seller address
    mapping(uint256=>address) public ownerAddress;

    //is listedFor selling
    mapping(uint256=>bool) public sellingList;

    function sellBike(address to, uint256 priceinwei, string memory uri) public onlyOwner {
    require(to != address(0), "Cannot Mint to zero address");
    require(bytes(uri).length > 0, "URI cannot be empty"); 

    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);

    ownerAddress[tokenId] = to;
    // bikePrice[tokenId] = (pricepercentage * 1e18) / 100;
    bikePrice[tokenId] = priceinwei;
    sellingList[tokenId] = true;
    // Set approval for the contract to manage all tokens owned by 'to'
    approve(address(this), tokenId);
    }


    function buy(address to,uint256 tokenId) public payable {

       require(sellingList[tokenId]==true,"Bike is not for selling");

       require(msg.value>=bikePrice[tokenId],"Low Balance");

        // Calculate remaining amount after deducting charges
        uint256 remainingAmount = msg.value - bikePrice[tokenId];
    
        // Send the calculated charges to the owner
        (bool success,) = ownerAddress[tokenId].call{value: bikePrice[tokenId]}("");
        
        //check if amount is send to owner
        require(success, "Failed to send money to owner");

        //send the NFT
        ERC721(address(this)).transferFrom(ownerAddress[tokenId], to, tokenId);

        //after payment set price of bike to zero
        bikePrice[tokenId]=0;

        //Removing from sellingList
        sellingList[tokenId]=false;
        ownerAddress[tokenId]=to;

        // Refund the remaining amount to the sender
        uint256 refundAmount = remainingAmount;
        
        //sent back the amount to user
        payable(msg.sender).transfer(refundAmount);
    }

    //Minting bike only owner
    function safeMint(address to, string memory uri,uint256 priceinwei) public onlyOwner {
        
        require(to!=address(0),"Cannot Mint to zero address");
        // Check if URI is not empty
        require(bytes(uri).length > 0, "URI cannot be empty"); 
        //Increment token count for each nft uniquely
        _tokenIdCounter.increment();
        //Save Current token counter
        uint256 tokenId = _tokenIdCounter.current();
        //mintNFt to specific address
        _safeMint(to, tokenId);
        //set the URI of the NFT
        _setTokenURI(tokenId, uri);

        chargeRate[tokenId]=priceinwei;
    }
    
    function listNFT(uint256 tokenId)public{
        //check if the sender has the same token ownership
        require(msg.sender==ownerOf(tokenId),"You dont have that NFT token!");
        //list nft for the Rent
        nftListed[tokenId]=true;
    }


    function changePrice(uint256 priceinwei,uint256 tokenId) public  returns (uint256) {
        require(ownerOf(tokenId)==msg.sender,"You are not the owner of the Bike");
        // require(percentage >= 0 && percentage <= 100, "Percentage out of range");
        // Convert the percentage to a decimal value
        uint256 decimalValue = priceinwei;
        
        chargeRate[tokenId]=decimalValue;

        return decimalValue;
    }

    function rentBike(address walletAddress,uint256 tokenId,uint64 starttime)public{
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        require(tokenId!=0,"Bike doesnot Existed");
        require(starttime!=0,"Start time cannot be zero");
        //Check If NFT is listed for the Rent
        require(nftListed[tokenId]==true,"You cannot rent the bike");
        require(rentedNFT[tokenId]==address(0),"You cannot rent this bike already Rented");
        require(activeRide[walletAddress]==false,"You already have the Bike Rented");
        // require(renters[walletAddress].due==0,"Pay Your Dues before Renting");
        //Set Active ride after renting a bike
        activeRide[walletAddress]=true;
       //set starting time for the ride
        startTime[walletAddress]=starttime;
        // canRent[walletAddress]=false;
        //set NFT for rent to keep them from transfering
        rentedNFT[tokenId]=walletAddress;
    }
    

    function returnBike(address walletAddress, uint64 endtime,uint256 tokenId) public payable {
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        require(tokenId!=0,"Bike doesnot Existed");
        require(endtime!=0,"End time cannot be zero");
        //check if already have an active Ride
        require(activeRide[walletAddress] == true, "You haven't rented a bike");
    
        // Calculate charges based on rental duration using the separate function
        uint256 charges = calculateCharges(walletAddress, endtime,tokenId);
    
        // Check if the sent value (msg.value) is sufficient to cover the charges
        require(msg.value >= charges, "Low balance for checkout");
    
        // Calculate remaining amount after deducting charges
        uint256 remainingAmount = msg.value - charges;
    
        // Send the calculated charges to the owner
        (bool success,) = owner().call{value: charges}("");
        
        //check if amount is send to owner
        require(success, "Failed to send money to owner");

        //after payment setting active ride false
        activeRide[walletAddress]=false;

        //Removing nft from rent
        rentedNFT[tokenId]=address(0);

        //Reseting StartTime
        startTime[walletAddress]=0;

        // Refund the remaining amount to the sender
        uint256 refundAmount = remainingAmount;
        //sent back the amount to user
        payable(msg.sender).transfer(refundAmount);
    }


    function calculateCharges(address walletAddress, uint64 endtime,uint256 tokenId) public view returns (uint256) {
        //If active Ride then calculate charges
        require(activeRide[walletAddress] == true, "You have not rented any bike");
        //check the starting time for the Ride
        uint256 starttime = startTime[walletAddress];
        //startime and Endtime cannot be same
        require(endtime!=starttime,"Start and End Time Cannot same");
        require(starttime < endtime, "Start time must be less than end time");
        //calculate time difference from start and end
        uint256 calculateTimeInBetween = endtime - starttime;
        //calculate time in minutes  
        uint256 timeSpanInMinutes = calculateTimeInBetween / 60;
        //calculate time increment 30 minutes with perthirty minute .5 eth charges  
        uint256 thirtyMinuteCharge = (timeSpanInMinutes / 30) * chargeRate[tokenId]; // Charging 0.5 ETH per 30 minutes
        //return the charge amount
        return thirtyMinuteCharge;
    }

    
    //get contract balance 
    function balanceof() view public returns(uint){
        //return the contract balance
        return address(this).balance;
    }

    //withdraw any amount from the contract
    function withdraw() public onlyOwner { 
        //check amount to withdraw   
        uint256 amount = address(this).balance;
        
        require(amount > 0, "Nothing to withdraw; contract balance empty");
        //owner account of contract
        address _owner = owner();
        
        //sent the amount to owner
        (bool sent, ) = _owner.call{value: amount}("");
        //check if sent or not
        require(sent, "Failed to send Ether");
    }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)internal override(ERC721, ERC721Enumerable){

    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);

    //    if (rentedNFT[tokenId] != address(0) ) {
    //     if(sellingList[tokenId] == false){
    //         require(false, "Transfer not allowed");
    //         }}
    // }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);

    if (rentedNFT[tokenId] != address(0) && sellingList[tokenId] == false) {
        require(false, "Transfer not allowed");
    }
    }



    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
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
}