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
        //mints nft with price
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
        //mints nft with price
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

     function testrentBikeWithRetureWithZeroTokenId()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("Bike doesnot Existed");
        nft_contract.returnBike{value:1 ether}(user,1692093911,0);
        assertEq(address(user).balance,2 ether);
    }

     function testrentBikeWithRetureWithZeroEndTime()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("End time cannot be zero");
        nft_contract.returnBike{value:1 ether}(user,0,1);
        assertEq(address(user).balance,2 ether);
    }

    function testrentBikeWithRetureWithsameTime()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("Start and End Time Cannot same");
        nft_contract.returnBike{value:1 ether}(user,1692092111,1);
        assertEq(address(user).balance,2 ether);
    }

     function testrentBikeWithRetureWithstartTimegreaterthanEnd()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092113);
        assertEq(nft_contract.rentedNFT(1),user);
        vm.expectRevert("Start time must be less than end time");
        nft_contract.returnBike{value:1 ether}(user,1692092111,1);
        assertEq(address(user).balance,2 ether);
    }

    function testrentBikeWithReture()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        assertEq(address(owner).balance,0.4 ether);
        assertEq(address(user).balance,1.6 ether);
    }
    

    function testrentedBikeCannotBeTransfer()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        assertEq(nft_contract.nftListed(1),true);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("Transfer not allowed");
        nft_contract.transferFrom(owner,user,1);
    }

    function testrentedbikeReturnCanbeTransfered() public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        assertEq(address(owner).balance,0.4 ether);
        assertEq(address(user).balance,1.6 ether);
        vm.startPrank(owner);
        nft_contract.transferFrom(owner,address(3),1);
        assertEq(nft_contract.ownerOf(1),address(3));
    }

     function testrentBikeWithReturePriceChange()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc",400000000000000000);
        nft_contract.changePrice(200000000000000000,1);
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        assertEq(address(owner).balance,0.2 ether);
        assertEq(address(user).balance,1.8 ether);
    }


    function testsellandBuy() public {
        vm.startPrank(owner);
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        assertEq(nft_contract.ownerOf(1),owner);
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        vm.stopPrank();
        vm.startPrank(address(3));
        vm.deal(address(3),2 ether);
        nft_contract.buy{value:1 ether}(address(3),1);
        assertEq(address(3).balance,1 ether);
        assertEq(address(owner).balance,1 ether);
        assertEq(nft_contract.ownerOf(1),address(3));
    }

    function testbuyWrongPrice() public {
        vm.startPrank(owner);
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        assertEq(nft_contract.ownerOf(1),owner);
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        vm.stopPrank();
        vm.startPrank(address(3));
        vm.deal(address(3),2 ether);
        vm.expectRevert("Low Balance");
        nft_contract.buy{value:0.5 ether}(address(3),1);
    }

     function testsellZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Cannot Mint to zero address");
        nft_contract.sellBike(address(0),1000000000000000000,"abc");
        vm.stopPrank();
    }

    function testcannotSellEmptyURI() public {
        vm.startPrank(owner);
        vm.expectRevert("URI cannot be empty");
        nft_contract.sellBike(owner,1000000000000000000,"");
        vm.stopPrank();
    }

      function testbuytwice() public {
        vm.startPrank(owner);
        nft_contract.sellBike(owner,1000000000000000000,"abc");
        assertEq(nft_contract.ownerOf(1),owner);
        assertEq(nft_contract.bikePrice(1),1000000000000000000);
        vm.stopPrank();
        vm.startPrank(address(3));
        vm.deal(address(3),2 ether);
        nft_contract.buy{value:1 ether}(address(3),1);
        assertEq(nft_contract.ownerOf(1),address(3));
        vm.startPrank(address(2));
        vm.expectRevert("Bike is not for selling");
        vm.deal(address(2),2 ether);
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
  
}