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

    constructor() ERC721("MyToken", "MTK")
    {
    }

    //Events 
    event Mint(address indexed to,uint256 tokenId,string uri);
    event onRent(address indexed to,uint256 tokenId, uint256 priceInWei);
    event onDisplay(address indexed to,uint256 tokenId,uint256 priceInWei);
    event rentBike(address indexed to,uint256 tokenId,uint256 startTimeValue);
    event returnBike(address indexed to,uint256 tokenId,uint256 endTime);
    event boughtBike(address indexed to,uint256 tokenId,uint256 price);

    //compensation for five minute charge 0.1 eth
    uint256 public compensationAmount=100000000000000000;

    //chargeRate mapping for different Bikes
    mapping(uint256=>uint256) public chargeRate;

    //mapping to sell bike
    mapping(uint256=>uint256) public bikePrice;

    //mapping to keep track of rentedbikes
    mapping (uint256=>address) public rentedNFT;
    
    //mapping to charge amount for user;
    mapping(address=>uint256) public amountToCharge;

    //Mapping to track startingTime for a ride
    mapping(address=>uint256) public startTime;
   
    //Mapping to keep track of Listed Bikes for Rent
    mapping(uint256=>bool) public nftForRent;

    //is listedFor selling
    mapping(uint256=>bool) public availableBikes;

    //Mapping for keeping userride active when rented otherwise false
    mapping(address=>bool) public activeRide;

     /*
     * @notice Enables to Mint NFT Bikes
     * @param to address where NFT needs to mint
     * @param uri data related to nft.
     * 
     * Function should be perform by onlyOwner.
    */

    function safeMint(address to, string memory uri) public onlyOwner {
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
        emit Mint(to,tokenId,uri);
    }


    /*
     * @notice Enables to list the minted NFT for Renting
     * @param tokenId list the specific tokenId.
     * @param priceinwei the chargePrice perthirty minute
     * 
     * Function can be call by anyone.
    */
    function listForRent(address to,uint256 tokenId,uint256 priceInWei)public{
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenId doesnot Exist");
        require(priceInWei!=0,"Price cannot be zero");
        require(nftForRent[tokenId] == false, "Already listed for rent");
        require(availableBikes[tokenId] == false, "Already listed for selling");
        //check if the sender has the same token ownership
        require(to==ownerOf(tokenId),"You dont have that NFT token!");
        //list nft for the Rent
        nftForRent[tokenId]=true;
        chargeRate[tokenId]=priceInWei;
        emit onRent(to,tokenId,priceInWei);
    }


    /*
     * @notice Enables to list nft(bike) for selling
     * @param to address where NFT needs to mint
     * @param priceinwei price of the nft(bike) in eth(wei).
     * 
     * Function should be perform by onlyOwner.
    */
    function displayBikeForSale(address to,uint256 tokenId, uint256 priceInWei) public {
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenId doesnot Exist");
        require(priceInWei!=0,"Price cannot be zero");
        require(nftForRent[tokenId] == false, "Already listed for rent");
        require(availableBikes[tokenId]==false,"Cannot Relist to Sell ");
        //check if the sender has the same token ownership
        require(to==ownerOf(tokenId),"You dont have that NFT token!");
        bikePrice[tokenId] = priceInWei;
        availableBikes[tokenId] = true;
        // Set approval for the contract to manage all tokens owned by 'to'
        approve(address(this), tokenId);
        emit onDisplay(to,tokenId,priceInWei);
    }

    /*
     * @notice Enables to remove the nft from renting
     * @param to address tokenowner 
     * @param priceinwei price of the nft(bike) in eth(wei).
     * 
     * Function should be perform by anyone.
    */
     function removefromrented(address to,uint256 tokenId) public {
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenId doesnot Exist");
        require(nftForRent[tokenId]==true,"List First");
        //check if the sender has the same token ownership
        require(to==ownerOf(tokenId),"You dont have that NFT token!");
        chargeRate[tokenId] = 0;
        nftForRent[tokenId] = false;   
    }

    /*
     * @notice Enables to remove the list nft(bike) for selling
     * @param to address tokenOwner
     * @param priceinwei price of the nft(bike) in eth(wei).
     * 
     * Function should be perform by anyone.
    */
    function removefromdisplay(address to,uint256 tokenId) public {
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenId doesnot Exist");
        require(availableBikes[tokenId]==true,"List First");
        //check if the sender has the same token ownership
        require(to==ownerOf(tokenId),"You dont have that NFT token!");
        bikePrice[tokenId] = 0;
        availableBikes[tokenId] = false;   
    }

    /*
     * @notice Enables to update price for the bike.
     * @param address to address of the tokenowner
     * @param tokenId specific tokenId
     * @param priceInWei price of the token
     * Function should be perform by anyone.
    */
    function updateBikePrice(address to,uint256 tokenId,uint256 priceInWei) public{
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"Cannot update to zero address");
        require(priceInWei!=0,"Price cannot be zero");
        require(to==ownerOf(tokenId),"You dont have that NFT token!");
        require(availableBikes[tokenId]==true,"List Bike for Selling First");
        bikePrice[tokenId]=priceInWei;
    }

    /*
     * @notice Enables to view compensation amount.
     * 
     * Function should be perform by owner only.
    */
    function getCompensationAmount() public view onlyOwner returns(uint256){
        return compensationAmount;
    }

    /*
     * @notice Enables to update compensation amount 
     * @param uint256 priceinwei update price of compensation
     * 
     * Function should be perform by owner only.
    */
    function updateCompensation(uint256 priceInWei)public onlyOwner returns(uint256){
        compensationAmount=priceInWei;
        return compensationAmount;
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
    function buyBike(address to,uint256 tokenId) public payable {
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenID doesnot Exist");
        //check if tokenid is listed for selling
        require(availableBikes[tokenId]==true,"Bike is not for selling");

        //check if msg.value is greater than the price of nft
        require(msg.value>=bikePrice[tokenId],"Low Balance");

        // Calculate remaining amount after deducting charges
        uint256 remainingAmount = msg.value - bikePrice[tokenId];
    
        // Send the calculated charges to the owner
        (bool success,) = ownerOf(tokenId).call{value: bikePrice[tokenId]}("");
        
        //check if amount is send to owner
        require(success, "Failed to send money to owner");

        //Removing from sellingList
        availableBikes[tokenId]=false;
        //send the NFT
        ERC721(address(this)).transferFrom(ownerOf(tokenId), to, tokenId);

        emit boughtBike(to,tokenId,bikePrice[tokenId]);
        
        //after payment set price of bike to zero
        bikePrice[tokenId]=0;

        // Refund the remaining amount to the sender
        uint256 refundAmount = remainingAmount;
        
        //sent back the amount to user
        payable(msg.sender).transfer(refundAmount);    
    }

     /*
     * @notice Enables to change price for renting bikes charges.
     * @param priceinwei to set new price.
     * @param tokenId to get the specific tokenId.
     * 
     * Function can be call by anyone.
    */
    function changeRentPrice(address to,uint256 priceInWei,uint256 tokenId) public returns (uint256) {
        require(to!=address(0),"Cannot Give Zero Address");
        require(tokenId!=0,"TokenId doesnot Exist");
        require(priceInWei!=0,"Price cannot be zero");
        require(ownerOf(tokenId)==to,"You are not the owner of the Bike");
        uint256 decimalValue = priceInWei;
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
    function rentaBike(address walletAddress,uint256 tokenId,uint64 startTimeValue) public {
        //check if address is not a zero address
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        //check if tokenId is not zero 
        require(tokenId!=0,"Bike doesnot Existed");
        //check for start time is not set to zero
        require(startTimeValue!=0,"Start time cannot be zero");
        //Check If NFT is listed for the Rent
        require(nftForRent[tokenId]==true,"you cannot rent the bike");
        //check if no one else has rented that nft
        require(rentedNFT[tokenId]==address(0),"You cannot rent this bike already Rented");
        //check if user have other active ride
        require(activeRide[walletAddress]==false,"You already have the Bike Rented");
        //Set Active ride after renting a bike
        activeRide[walletAddress]=true;
       //set starting time for the ride
        startTime[walletAddress]=startTimeValue;
        //set NFT for rent to keep them from transfering
        rentedNFT[tokenId]=walletAddress;
        //charge amount first time when pick
        amountToCharge[walletAddress]=chargeRate[tokenId];

        emit rentBike(walletAddress,tokenId,startTimeValue);
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
    function returnaBike(address walletAddress, uint64 endTime,uint256 tokenId) public payable {
        //check if wallet is not a zero address
        require(walletAddress!=address(0),"Cannot Rent to zero Address");
        //check if tokenId is not a zero address
        require(tokenId!=0,"Bike doesnot Existed");
        //check if endtime isnot a zero address
        require(endTime!=0,"End time cannot be zero");
        //check if already have an active Ride
        require(activeRide[walletAddress] == true, "You haven't rented a bike");
    
        // Calculate charges based on rental duration using the separate function
        uint256 charges = calculateCharges(walletAddress, endTime,tokenId);
    
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

        emit returnBike(walletAddress,tokenId,endTime);
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

    function calculateCharges(address walletAddress, uint64 endTime, uint256 tokenId) public returns (uint256) {
        require(activeRide[walletAddress] == true, "You have not rented any bike");
        uint256 starttime = startTime[walletAddress];
        require(endTime != starttime, "Start and End Time Cannot be the same");
        require(starttime < endTime, "Start time must be less than end time");
        uint256 calculateTimeInBetween = endTime - starttime;
        uint256 timeSpanInMinutes = calculateTimeInBetween / 60;
        uint256 timeSpanPerthirty = timeSpanInMinutes / 30;

        if (timeSpanPerthirty == 0) {
            uint256 chargeAmount = amountToCharge[walletAddress];
            return chargeAmount;
        }

        amountToCharge[walletAddress] = 0;
        uint256 compensation = ((timeSpanInMinutes % 30) / 5) * compensationAmount;
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

        if (nftForRent[tokenId] || availableBikes[tokenId]) {
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