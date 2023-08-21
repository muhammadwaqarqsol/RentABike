// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rentabike is  ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public compensationamount=100000000000000000;

    constructor() ERC721("MyToken", "MTK")
    {
    }
    //chargeRate mapping for different Bikes
    mapping(uint256=>uint256) public chargeRate;

     //mapping to charge amount for user;
    mapping(address=>uint256) public amounttoCharge;

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


    /*
     * @notice Enables to list nft(bike) for selling (Minting at the new token)
     * @param to address where NFT needs to mint
     * @param priceinwei price of the nft(bike) in eth(wei).
     * @param uri data related to nft.
     * 
     * Owner mints nft and list it for selling with price.
     * Function should be perform by owner only.
    */
    function sellBike(address to, uint256 priceinwei, string memory uri) public onlyOwner {
        //check if address is not zero address
        require(to != address(0), "Cannot Mint to zero address");
        //check if uri is not empty
        require(bytes(uri).length > 0, "URI cannot be empty"); 
        //incrementing id
        _tokenIdCounter.increment();
        //stroing current id
        uint256 tokenId = _tokenIdCounter.current();
        //minting to address with that store id
        _safeMint(to, tokenId);
        //setting uri for the tokenId
        _setTokenURI(tokenId, uri);

        ownerAddress[tokenId] = to;
        // bikePrice[tokenId] = (pricepercentage * 1e18) / 100;
        bikePrice[tokenId] = priceinwei;
        sellingList[tokenId] = true;
        // Set approval for the contract to manage all tokens owned by 'to'
        approve(address(this), tokenId);
    }

    /*
     * @notice Enables to view compensation amount.
     * 
     * Function should be perform by owner only.
    */
    function getCompensationamount() public view onlyOwner returns(uint256){
        return compensationamount;
    }

    /*
     * @notice Enables to update compensation amount 
     * @param uint256 priceinwei update price of compensation
     * 
     * Function should be perform by owner only.
    */
    function updateCompensation(uint256 priceinwei)public onlyOwner{
        compensationamount=priceinwei;
    }

    /*
     * @notice Enables to buy nft(bike) with price.
     * @param to address where NFT needs to transfer
     * @param tokenId nftId you need to buy.
     * 
     * @function payable needs to pay ethers
     * 
     * Function should be perform by anyone can call this function and buys nft and it will remove listing
     * and update owner of nft.
    */
    function buy(address to,uint256 tokenId) public payable {
        //check if tokenid is listed for selling
       require(sellingList[tokenId]==true,"Bike is not for selling");

        //check if msg.value is greater than the price of nft
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

    /*
     * @notice Enables to Mint new nft(bike) with price and URI.
     * @param to address where NFT needs to mint
     * @param uri data related to nft.
     * @param priceinwei price of the nft(bike) in eth(wei) for perthirty minute charge on renting.
     * 
     * Function should be perform by onlyOwner.
    */
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
    
     /*
     * @notice Enables to list the minted NFT for Renting
     * @param tokenId list the specific tokenId.
     * 
     * Function can be call by onlyOwner.
    */
    function listNFT(uint256 tokenId)public onlyOwner{
        //check if the sender has the same token ownership
        require(msg.sender==ownerOf(tokenId),"You dont have that NFT token!");
        //list nft for the Rent
        nftListed[tokenId]=true;
    }


     /*
     * @notice Enables to change price for renting bikes charges.
     * @param priceinwei to set new price.
     * @param tokenId to get the specific tokenId.
     * 
     * Function can be call by onlyOwner.
    */
    function changePrice(uint256 priceinwei,uint256 tokenId) public onlyOwner returns (uint256) {
        require(ownerOf(tokenId)==msg.sender,"You are not the owner of the Bike");
        // require(percentage >= 0 && percentage <= 100, "Percentage out of range");
        // Convert the percentage to a decimal value
        uint256 decimalValue = priceinwei;
        //updating mapping
        chargeRate[tokenId]=decimalValue;

        return decimalValue;
    }

    /*
     * @notice Enables to rent bike for price on per thirty minute.
     * @param walletAdress user address.
     * @param tokenId to get the specific tokenId.
     * @param starttime unix time stamp for starttime.
     * 
     * Function can be call by anyone.
    */
    function rentBike(address walletAddress,uint256 tokenId,uint64 starttime) public {
        //check if address is not a zero address
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        //check if tokenId is not zero 
        require(tokenId!=0,"Bike doesnot Existed");
        //check for start time is not set to zero
        require(starttime!=0,"Start time cannot be zero");
        //Check If NFT is listed for the Rent
        require(nftListed[tokenId]==true,"You cannot rent the bike");
        //check if no one else has rented that nft
        require(rentedNFT[tokenId]==address(0),"You cannot rent this bike already Rented");
        //check if user have other active ride
        require(activeRide[walletAddress]==false,"You already have the Bike Rented");
        //Set Active ride after renting a bike
        activeRide[walletAddress]=true;
       //set starting time for the ride
        startTime[walletAddress]=starttime;
        //set NFT for rent to keep them from transfering
        rentedNFT[tokenId]=walletAddress;
        //charge amount first time when pick
        amounttoCharge[walletAddress]=chargeRate[tokenId];
    }
    
     /*
     * @notice Enables to return the rented bike for price on per thirty minute charges.
     * @param walletAdress user address.
     * @param tokenId to get the specific tokenId.
     * @param endtime unix time stamp for endtime ride.
     * 
     * @function payable needs to pay ether
     * 
     * Function can be call by anyone.
    */
    function returnBike(address walletAddress, uint64 endtime,uint256 tokenId) public payable {
        //check if wallet is not a zero address
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        //check if tokenId is not a zero address
        require(tokenId!=0,"Bike doesnot Existed");
        //check if endtime isnot a zero address
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

     /*
     * @notice Enables to calculate charges for rented Bikes.
     * @param walletAdress user address.
     * @param tokenId to get the specific tokenId.
     * @param endtime unix time stamp for endtime.
     * 
     * @require needs to have active ride else it won't calculate
     * 
     * Function can be call by anyone.
    */

    function calculateCharges(address walletAddress, uint64 endtime, uint256 tokenId) public returns (uint256) {
        require(activeRide[walletAddress] == true, "You have not rented any bike");
        uint256 starttime = startTime[walletAddress];
        require(endtime != starttime, "Start and End Time Cannot be the same");
        require(starttime < endtime, "Start time must be less than end time");
        uint256 calculateTimeInBetween = endtime - starttime;
        uint256 timeSpanInMinutes = calculateTimeInBetween / 60;
        uint256 timeSpanPerthirty = timeSpanInMinutes / 30;

        if (timeSpanPerthirty == 0) {
            uint256 chargeAmount = amounttoCharge[walletAddress];
            return chargeAmount;
        }

        amounttoCharge[walletAddress] = 0;
        uint256 compensation = ((timeSpanInMinutes % 30) / 5) * compensationamount;
        uint256 totalCharge = (timeSpanPerthirty * chargeRate[tokenId]) + compensation;
        return totalCharge;
    }

     /*
     * @notice Enables to check balance of the contract.
     * 
     * Function can be call by onlyOwner.
    */
    //get contract balance 
    function balanceof() view public onlyOwner returns(uint){
        //return the contract balance
        return address(this).balance;
    }   
     /*
     * @notice Enables to withdraw funds from the contract.
     * 
     * Function can be call by onlyOwner.
    */

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

    /*
     * @notice Enables to check token(NFT) transfer before the trancation is processed.
     * @param from owner address
     * @param to where to transfer
     * @param tokenId specific tokenId
     * 
     * @calls automatically runs for each transfer
     * 
     * @require nft is not listed in selling bike or not rented 
     * if both are false then it will allow transfer
     * 
     * Function can be call by anyone.
    */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (rentedNFT[tokenId] != address(0) && sellingList[tokenId] == false) {
            require(false, "Transfer not allowed");
        }
    }


     /*
     * @notice just an override function required to use ERC721URI storage 
     * 
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    
    }

     /*
     * @notice just an override function required to use ERC721URI storage 
     * 
    */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage)returns (string memory){
        return super.tokenURI(tokenId);
    }


     /*
     * @notice just an override function required to use ERC721Enumerable 
     * 
    */
    function supportsInterface(bytes4 interfaceId)public view override(ERC721, ERC721Enumerable)returns (bool){
        return super.supportsInterface(interfaceId);
    }
}