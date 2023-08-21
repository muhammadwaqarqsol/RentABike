// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../contracts/NFTRent.sol";

contract BikeRentTest is Test {
    //contract instance for rentabike
    Rentabike public nft_contract; 

    //owner address and private key 
    uint256 internal ownerPrivateKey;
    address internal owner;
    
    //user address and private key 
    uint256 internal userPrivateKey;
    address internal user;

    //function setups contract for test
    function setUp() public {
        //deploy instance of smart contract
        nft_contract = new Rentabike();

        //sets owner private key and address
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        //sets owner user private key and address
        userPrivateKey = 0xB0B;
        user = vm.addr(userPrivateKey);

        //transfer ownership to owner
        nft_contract.transferOwnership(owner);
        //give user 2 eth for testing
        vm.deal(user, 2 ether);
    }

    //test initial start
    function testInitial() public {
        //checking if owner has zero nft (Zero NFT minted)
        assertEq(nft_contract.balanceOf(owner), 0);
    }

    //testing mintNFT for rent
    function testmintNFt() public {
        //starting owner as initiater
        vm.startPrank(owner);
        //mint nft with price
        nft_contract.safeMint(owner,"abc",200000000000000000);
        //interaction stop
        vm.stopPrank();
        //check if owner is correct
        assertEq(nft_contract.ownerOf(1), owner);
        //check if total supply is one
        assertEq(nft_contract.totalSupply(),1);
    }

    //failing test case to check if nft is not minting to zero address
     function testmintNFtZeroAddress() public {
        //starting owner as initiater
        vm.startPrank(owner);
        //reverting become address is zero
        vm.expectRevert("Cannot Mint to zero address");
        //call with zero address to be reverted
        nft_contract.safeMint(address(0),"abc",300000000000000000);
        //call to be reverted if URI is empty
        vm.expectRevert("URI cannot be empty");
        //calls with Empty URI
        nft_contract.safeMint(owner,"",300000000000000000);
         //interaction stop
        vm.stopPrank();
    }

    //test for List nft as renting and listing
    function testRentBikeWithList()public{
        //starting owner as initiater
        vm.startPrank(owner);
        //mint nft with price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list the NFT for renting
        nft_contract.listNFT(1);
        //interaction stop
        vm.stopPrank();
        //check is nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //interaction start as user to rent
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
    }

    //test for minted nft but not listed for rent to check if they can be rented
    function testcannotRentWithOutListing()public{
        //start interaction
         vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //stop interaction
        vm.stopPrank();
        //check if nft is not list
        assertEq(nft_contract.nftListed(1),false);
         //interaction start as user to rent
        vm.startPrank(user);
        //nft not list to be reverted
        vm.expectRevert("You cannot rent the bike");
        //calling rentBike without listed TokenId
        nft_contract.rentBike(user,1,1692092111);
    }

    //test for minted nft but not listed for rent to check if they can be rented
     function testcannotRentWithZeroAddress()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list the NFT for renting
        nft_contract.listNFT(1);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero address
        vm.expectRevert("Cannot Rent to zero Address");
        //calls rent with zero address
        nft_contract.rentBike(address(0),1,1692092111);
    }

    //test cannot rent the zero tokenId
    function testcannotRentWithZeroTokenID()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list the NFT for renting
        nft_contract.listNFT(1);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero tokenId
        vm.expectRevert("Bike doesnot Existed");
         //calls rent with zero tokenId
        nft_contract.rentBike(user,0,1692092111);
    }

    //test cannot rent with start time as zero
    function testcannotRentWithZeroStartTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list the NFT for renting
        nft_contract.listNFT(1);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero starttime
        vm.expectRevert("Start time cannot be zero");
          //calls rent with zero starttime
        nft_contract.rentBike(user,1,0);
    }

    //test for renting same bike twice 
    function testRentsameBikeTwice()public{
        //start interaction as owner
        vm.startPrank(owner);
        
        //mint nft to the owner
        nft_contract.safeMint(owner,"abc",400000000000000000);
        
        //list nft for rent
        nft_contract.listNFT(1);
        
        //stop interaction as owner
        vm.stopPrank();

        //check if nft is rented for the the 
        assertEq(nft_contract.nftListed(1),true);
        
        //interaction to set as user
        vm.startPrank(user);

        //rent a listed bike by user
        nft_contract.rentBike(user,1,1692092111);

        //check if user has rented the bike
        assertEq(nft_contract.rentedNFT(1),user);

        //start interaction as user address 3
        vm.startPrank(address(3));

        //call to be reverted bike already rented
        vm.expectRevert("You cannot rent this bike already Rented");

        //nft contract address 3 is calling rent on rented Bike
        nft_contract.rentBike(address(3),1,1692092111);
    }

    //test for return without rent or active ride
    function testbikeReturnWithoutactiveRide() public{
        //start interaction as user
        vm.startPrank(user);
        //expected revert without rent
        vm.expectRevert("You haven't rented a bike");
        //contract call to return bike without rent
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
    }

    //test for return bike with zero address
    function testrentBikeWithRetureWithZeroAddress()public{
        //start interaction as owner
        vm.startPrank(owner);
        //start minting nft and setting price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //listing nft for rent
        nft_contract.listNFT(1);
        //interation stop
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike
        nft_contract.rentBike(user,1,1692092111);
        //check if bike is rented by the same user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start address is same as user
        assertEq(nft_contract.startTime(user),1692092111);
        //expected revert for zero address
        vm.expectRevert("Cannot Rent to zero Address");
        //return bike with zero address
        nft_contract.returnBike{value:1 ether}(address(0),1692093911,1);
        //check if balance is intact
        assertEq(address(user).balance,2 ether);
    }

    //test for return with zero tokenId
    function testrentBikeWithRetureWithZeroTokenId()public{
        //starting to interact as owner
        vm.startPrank(owner);
        //start minting nft and setting price
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //listing nft for rent
        nft_contract.listNFT(1);
        //interation stop
        vm.stopPrank();
        //Check if nft is listed for the rent
        assertEq(nft_contract.nftListed(1),true);
         //starting to interact as user
        vm.startPrank(user);
        //calling rent Function
        nft_contract.rentBike(user,1,1692092111);
        //checkif nft is rented by the same user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is same or not
        assertEq(nft_contract.startTime(user),1692092111);
        //revert the Bike does not exist when returning 0 tokenId
        vm.expectRevert("Bike doesnot Existed");
        //return bike call for nft to be reverted
        nft_contract.returnBike{value:1 ether}(user,1692093911,0);
        //check if the balance is intact and is not being used.
        assertEq(address(user).balance,2 ether);
    }

    //test for rent bike with return (but end time is zero)
     function testrentBikeWithRetureWithZeroEndTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //stops interaction as owner
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentBike(user,1,1692092111);
        //check if bike is rented by correct user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //revert if end time is zero 
        vm.expectRevert("End time cannot be zero");
        //return bike with payment but zero end time
        nft_contract.returnBike{value:1 ether}(user,0,1);
        //check if user balance is intact
        assertEq(address(user).balance,2 ether);
    }

    //check if test rent bike with start and endtime saem
    function testrentBikeWithRetureWithsameTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft 
        nft_contract.listNFT(1);
        //stops interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftListed(1),true);
        //interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentBike(user,1,1692092111);
        //check if nft is rented by user or not
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time for a user is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //revert if and end time are same
        vm.expectRevert("Start and End Time Cannot be the same");
        //return bike with same time as start time
        nft_contract.returnBike{value:1 ether}(user,1692092111,1);
        //check if user balance is same and is not charged
        assertEq(address(user).balance,2 ether);
    }

    //test for rent bike with return where starttime is more than end time
    function testrentBikeWithRetureWithstartTimegreaterthanEnd()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list the nft
        nft_contract.listNFT(1);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftListed(1),true);
        //starting interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentBike(user,1,1692092113);
        //check if bike is rented by user or not
        assertEq(nft_contract.rentedNFT(1),user);
        //revert if time is mismatched and less than
        vm.expectRevert("Start time must be less than end time");
        //nft return with start time greature than end time
        nft_contract.returnBike{value:1 ether}(user,1692092111,1);
        //check if user balance is same and is not charged
        assertEq(address(user).balance,2 ether);
    }

    //test for bike nft return with sell and return 
    function testrentBikeWithReture()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //stop interaction
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent nft as user
        nft_contract.rentBike(user,1,1692092111);
        //check if nft is rented by the user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.4 ether);
        //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.6 ether);
    }
    
    //test for bike cannot be transfer when rented
    function testrentedBikeCannotBeTransfer()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //check if nft is listed or not
        assertEq(nft_contract.nftListed(1),true);
        //rent bike as user
        nft_contract.rentBike(user,1,1692092111);
        //check if bike renter is user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //expected revert on transfered
        vm.expectRevert("Transfer not allowed");
        //transferring the rented nft 
        nft_contract.transferFrom(owner,user,1);
    }

    //test for bike return and is not rented can be transfered
    function testrentedbikeReturnCanbeTransfered() public{
        //starting interaction as owner
        vm.startPrank(owner);
        //created nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentBike(user,1,1692092111);
        //check if bike is rented by correct user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct or not
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        //check if owner balance is increased 
        assertEq(address(owner).balance,0.4 ether);
        //check is user balance is decreased. 
        assertEq(address(user).balance,1.6 ether);
        //start interaction as owner
        vm.startPrank(owner);
        //trasferring nft to address 3
        nft_contract.transferFrom(owner,address(3),1);
        //check if nft is transferred and owner is updated.
        assertEq(nft_contract.ownerOf(1),address(3));
    }

    //test for bike return with price change after mint price
     function testrentBikeWithReturePriceChange()public{
        //start interaction as owner
        vm.startPrank(owner);
        //minting nft 
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //changing price after nft mint
        nft_contract.changePrice(200000000000000000,1);
        //listing nft
        nft_contract.listNFT(1);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike
        nft_contract.rentBike(user,1,1692092111);
        //check if bike is rented to user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if starting time is correct or not
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        //check if owner recieved the amount
        assertEq(address(owner).balance,0.2 ether);
        //check if user balance is deducted correctly
        assertEq(address(user).balance,1.8 ether);
    }

    //test for buy and sell nft 
    function testsellandBuy() public {
        //start interaction as owner
        vm.startPrank(owner);
        //minting nft for selling bike
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        //check if owner is correct of nft or nor
        assertEq(nft_contract.ownerOf(1),owner);
        //check if bike price is correct 
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        //interaction stop
        vm.stopPrank();
        //starting to interact as address(3)
        vm.startPrank(address(3));
        //giving 2 ether to address 3
        vm.deal(address(3),2 ether);
        //buying nft 
        nft_contract.buy{value:1 ether}(address(3),1);
        //check if user beller is deducted
        assertEq(address(3).balance,1 ether);
        //check if owner balance of seller is incremented
        assertEq(address(owner).balance,1 ether);
        //check if nft is transfered and owner is updated
        assertEq(nft_contract.ownerOf(1),address(3));
    }

    //test for bike nft with wrong price
    function testbuyWrongPrice() public {
        //start interaction as owner
        vm.startPrank(owner);
        //selling bike nft to be minted
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        //check if owner is correct after the mint
        assertEq(nft_contract.ownerOf(1),owner);
        //check if the bike price is correct
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        //interaction stop
        vm.stopPrank();
        //starting interactioon as address(3)
        vm.startPrank(address(3));
        //giving 3 ether to address 3
        vm.deal(address(3),2 ether);
        //worng price to be reverted
        vm.expectRevert("Low Balance");
        //buying at low price than original
        nft_contract.buy{value:0.5 ether}(address(3),1);
    }

    //test for minting nft with zero address(Selling)
     function testsellZeroAddress() public {
        //starting interaction as owner
        vm.startPrank(owner);
        //expect revert with zero address sell mint
        vm.expectRevert("Cannot Mint to zero address");
        //call sell but address zero to mint
        nft_contract.sellBike(address(0),1000000000000000000,"abc");
        //stoping interaction
        vm.stopPrank();
    }

    //test for minting nft for selling with empty uri
    function testcannotSellEmptyURI() public {
        //start interaction as owner
        vm.startPrank(owner);
        //Empty uri revert Function
        vm.expectRevert("URI cannot be empty");
        //create bike nft with empty uri
        nft_contract.sellBike(owner,1000000000000000000,"");
        //stopping interaction
        vm.stopPrank();
    }

    //test function to buy twice
    function testbuytwice() public {
        //start interaction as owner
        vm.startPrank(owner);
        //creating nft for selling bike
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        //check if owner is correct
        assertEq(nft_contract.ownerOf(1),owner);
        //check if price is correct
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        //interaction stop
        vm.stopPrank();
        //starting to interact as address(3)
        vm.startPrank(address(3));
        //give 2 ether to address(3)
        vm.deal(address(3),2 ether);
        //buy nft using address 3
        nft_contract.buy{value:1 ether}(address(3),1);
        //check if nft is bough and owner is updated
        assertEq(nft_contract.ownerOf(1),address(3));
        //starting interaction as second user
        vm.startPrank(address(2));
        //expected revert if bike is not for sell
        vm.expectRevert("Bike is not for selling");
        //giving ethers to address 2 
        vm.deal(address(2),2 ether);
        //buying same nft which is updated and is not for sell
        nft_contract.buy{value:1 ether}(address(2),1);
    }

    //test for buying with listed for selling
     function testbuywithoutList() public {
        //start interaction as address 3 
        vm.startPrank(address(3));
        //giving ethers to address
        vm.deal(address(3),2 ether);
        //expected to be reverted for not list bike for selling
        vm.expectRevert("Bike is not for selling");
        //calling buy on not listed bike
        nft_contract.buy{value:1 ether}(address(3),1);
    }

    //test for bike listed cannot be transfer
      function testFailsellButcannotbeTransferred() public {
        //start interaction as owner
        vm.startPrank(owner);
        //listing bike for sell
        nft_contract.sellBike(user,1000000000000000000,"abc");
        //check if owner is owner
        assertEq(nft_contract.ownerOf(1),owner);
        //check if price is correct
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        //stops interaction
        vm.stopPrank();
        //start interaction as owner to transfer nft
        vm.startPrank(owner);
        //transfering nft token listed for selling
        nft_contract.transferFrom(user,owner, 1);
    }

     //test for bike nft return with sell and return 
    function testrentBikeWithReture_compensationamount()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //stop interaction
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent nft as user
        nft_contract.rentBike(user,1,1692092111);
        //check if nft is rented by the user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnBike{value:1 ether}(user,1692094271,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.5 ether);
        // //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.5 ether);
    }

     //test for bike nft return with sell and return 
    function testrentBikeWithReture_compensationamount_parttwo()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc",400000000000000000);
        //list nft for rent
        nft_contract.listNFT(1);
        //stop interaction
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftListed(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent nft as user
        nft_contract.rentBike(user,1,1692096000);
        //check if nft is rented by the user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692096000);
        //return bike with payment
        nft_contract.returnBike{value:1 ether}(user,1692098400,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.6 ether);
        // //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.4 ether);
    }
}