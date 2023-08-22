// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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


       //test initial start
    function testInitial() public {
        //checking if owner has zero nft (Zero NFT minted)
        assertEq(nft_contract.balanceOf(owner), 0);
    }

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

    //testing mintNFT for rent
    function testmintNFt() public {
        //starting owner as initiater
        vm.startPrank(owner);
        //mint nft with price
        nft_contract.safeMint(owner,"abc");
        //interaction stop
        vm.stopPrank();
        //check if owner is correct
        assertEq(nft_contract.ownerOf(1), owner);
        //check if total supply is one
        assertEq(nft_contract.totalSupply(),1);
    }

    //testcase for listing on rent
    function testlistonRent() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
    }

    //testcase for listing on rent
    function testdisplayBike() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        //interaction stop
        vm.stopPrank();
    }

     //testcase for listing on rent
    function testdisplayBikewithUpdatePrice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        //updateprice
        nft_contract.updateBikePrice(owner,1,5000000);
        assertEq(nft_contract.bikePrice(1),5000000);
        //interaction stop
        vm.stopPrank();
    }

    //test for getting compensation price by owner
    function testcompensationamountget() public{
        //starting owner as initiater
        vm.startPrank(owner);
        assertEq(nft_contract.getCompensationAmount(),100000000000000000);
    }

    //test for updating compensation amount
    function testupdatecompensationamountget() public{
        //starting owner as initiater
        vm.startPrank(owner);
        assertEq(nft_contract.getCompensationAmount(),100000000000000000);
        nft_contract.updateCompensation(1000000000);
        assertEq(nft_contract.getCompensationAmount(),1000000000);
    }


    // test buy bike
    function testbuyBike()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.displayBikeForSale(owner,1,1000000);
        assertEq(nft_contract.availableBikes(1),true);
        assertEq(nft_contract.bikePrice(1),1000000);
        vm.stopPrank();
        vm.startPrank(user);
        nft_contract.buyBike{value:1 ether}(user, 1);
        assertEq(nft_contract.availableBikes(1),false);
        assertEq(nft_contract.bikePrice(1),0);
    }

     // test buy bike
    function testbuysameBike()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.displayBikeForSale(owner,1,1000000);
        assertEq(nft_contract.availableBikes(1),true);
        assertEq(nft_contract.bikePrice(1),1000000);
        vm.stopPrank();
        vm.startPrank(user);
        nft_contract.buyBike{value:1 ether}(user, 1);
        assertEq(nft_contract.availableBikes(1),false);
        assertEq(nft_contract.bikePrice(1),0);
        vm.expectRevert("Bike is not for selling");
        nft_contract.buyBike{value:1 ether}(user, 1);
    }

    //testfor buying bike that is not listed
    function testbuyBikenotforSell()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        assertEq(nft_contract.availableBikes(1),false);
        assertEq(nft_contract.bikePrice(1),0);
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert("Bike is not for selling");
        nft_contract.buyBike{value:1 ether}(user, 1);
    }

    //test for displaying bike not minted
    function testdisplayBikeNotMinted()public{
        vm.startPrank(owner);
        vm.expectRevert("ERC721: invalid token ID");
        nft_contract.displayBikeForSale(owner,1,1000000);
        vm.stopPrank();
    }

    //test for displaying same bike twice
    function testdisplayBiketwice()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.displayBikeForSale(owner,1,1000000);
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Cannot Relist to Sell ");
        nft_contract.displayBikeForSale(owner,1,1000000);
        vm.stopPrank();
    }

    //test for displaying bike not owned 
    function testdisplayBikeNotOwned()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        vm.startPrank(user);
        vm.expectRevert("You dont have that NFT token!");
        nft_contract.displayBikeForSale(user,1, 1000000);
    }
    
    //test for rent a bike
    function testrentBikeandreturn() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.4 ether);
        //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.6 ether);
    }

    //test for rent a bike
    function testbikeReturnTwice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.4 ether);
        //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.6 ether);
        vm.expectRevert("You haven't rented a bike");
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
    }

     //test for rent a bike
    function testbikeRentTwice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
        assertEq(nft_contract.rentedNFT(1),user);
        vm.expectRevert("you cannot rent the bike");
        nft_contract.rentaBike(owner,1692093911,1);
    }

     //test for rent a bike
    function testbikeReturnwithoutRent() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        vm.expectRevert("You haven't rented a bike");
        nft_contract.returnaBike(owner,1692093911,1);
    }

    //test for minted nft but not listed for rent to check if they can be rented
    function testcannotRentWithOutListing()public{
        //start interaction
         vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc");
        //stop interaction
        vm.stopPrank();
        //check if nft is not list
        assertEq(nft_contract.nftForRent(1),false);
         //interaction start as user to rent
        vm.startPrank(user);
        //nft not list to be reverted
         vm.expectRevert("you cannot rent the bike");
        //calling rentBike without listed TokenId
        nft_contract.rentaBike(user,1,1692092111);
    }

     //test for rent a bike
    function testbikeReturnwithLowPrice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("Low balance for checkout");
        //return bike with payment
        nft_contract.returnaBike{value:0.3 ether}(user,1692093911,1);
    }    

    function testbikeReturnwithwrongAddress() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if is available on rent
        assertEq(nft_contract.nftForRent(1),true);
        //interaction stop
        vm.stopPrank();
        //as a user interaction
        vm.startPrank(user);
        //call to rent nft
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the same user address
        assert(nft_contract.rentedNFT(1)==user);
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("You haven't rented a bike");
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(owner,1692093911,1);
    }  

    //failing test case to check if nft is not minting to zero address
     function testmintNFtZeroAddress() public {
        //starting owner as initiater
        vm.startPrank(owner);
        //reverting become address is zero
        vm.expectRevert("Cannot Mint to zero address");
        //call with zero address to be reverted
        nft_contract.safeMint(address(0),"abc");
         //interaction stop
        vm.stopPrank();
    }
    
    //failing test case to check if nft is not minting to zero address
     function testmintemptyUri() public {
        //starting owner as initiater
        vm.startPrank(owner);
        //call to be reverted if URI is empty
        vm.expectRevert("URI cannot be empty");
        //calls with Empty URI
        nft_contract.safeMint(owner,"");
         //interaction stop
        vm.stopPrank();
    }

    
     //testcase for listing on rent
    function testlistonRentwithzeroAddress() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("Cannot Give Zero Address");
        //list for rent
        nft_contract.listForRent(address(0),1,4000000000000000000);
        //interaction stop
        vm.stopPrank();
    }

    //testcase for listing on rent
    function testlistonRentwithzeroTokenId() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("TokenId doesnot Exist");
        //list for rent
        nft_contract.listForRent(owner,0,4000000000000000000);
        //interaction stop
        vm.stopPrank();
    }

     //testcase for listing on rent
    function testlistonRentwithzeroPrice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("Price cannot be zero");
        //list for rent
        nft_contract.listForRent(owner,1,0);
        //interaction stop
        vm.stopPrank();
    }
    

    //testcase for listing on rent
    function testdisplayBikewithUpdatePricewithZeroAddress() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Cannot Give Zero Address");
        //updateprice
        nft_contract.updateBikePrice(address(0),1,5000000);
        //interaction stop
        vm.stopPrank();
    }

       //testcase for listing on rent
    function testdisplayBikewithUpdatePricewithZerotokenId() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Cannot update to zero address");
        //updateprice
        nft_contract.updateBikePrice(owner,0,5000000);
        //interaction stop
        vm.stopPrank();
    }

    //testcase for listing on rent
    function testdisplayBikewithUpdatePricewithZeroprice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Price cannot be zero");
        //updateprice
        nft_contract.updateBikePrice(owner,1,0);
        //interaction stop
        vm.stopPrank();
    }

    //testcase for listing on rent
    function testdisplayBikewithzeroAddress() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("Cannot Give Zero Address");
        //list for rent
        nft_contract.displayBikeForSale(address(0),1,4000000000000000000);
        //interaction stop
        vm.stopPrank();
    }

    //testcase for listing on rent
    function testdisplayBikewithzeroTokenId() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("TokenId doesnot Exist");
        //list for rent
        nft_contract.displayBikeForSale(owner,0,4000000000000000000);
        //interaction stop
        vm.stopPrank();
    }

     //testcase for listing on rent
    function testdisplayBikewithzeroPrice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //expect revert
        vm.expectRevert("Price cannot be zero");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,0);
        //interaction stop
        vm.stopPrank();
    }
    
    
     //testcase for listing on rent
    function testbuyBikewithUpdatePrice() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        //updateprice
        nft_contract.updateBikePrice(owner,1,5000000);
        assertEq(nft_contract.bikePrice(1),5000000);
        //interaction stop
        vm.stopPrank();
    }

      //testcase for listing on rent
    function testbuyBikewithUpdatePricewithZeroAddress() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Cannot Give Zero Address");
        //updateprice
        nft_contract.updateBikePrice(address(0),1,5000000);
        //interaction stop
        vm.stopPrank();
    }

       //testcase for listing on rent
    function testbuyBikewithUpdatePricewithZerotokenId() public{
        //starting owner as initiater
        vm.startPrank(owner);
        //call with zero address to be reverted
        nft_contract.safeMint(owner,"abc");
        //list for rent
        nft_contract.displayBikeForSale(owner,1,4000000000000000000);
        //check if is available on rent
        assertEq(nft_contract.availableBikes(1),true);
        vm.expectRevert("Cannot update to zero address");
        //updateprice
        nft_contract.updateBikePrice(owner,0,5000000);
        //interaction stop
        vm.stopPrank();
    }

     //test for bike nft return with sell and return 
    function testrentBikeWithReture_compensationamount_parttwo()public{
        //start interaction as owner
        vm.startPrank(owner);
        //start minting nft and setting price
        nft_contract.safeMint(owner,"abc");
        //listing nft for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //interation stop
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent nft as user
        nft_contract.rentaBike(user,1,1692096000);
        //check if nft is rented by the user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692096000);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692098400,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.6 ether);
        // //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.4 ether);
    }

      //test for bike nft return with sell and return 
    function testrentBikeWithReture_compensationamount()public{
        vm.startPrank(owner);
         //start minting nft and setting price
        nft_contract.safeMint(owner,"abc");
        //listing nft for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //interation stop
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent nft as user
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by the user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692094271,1);
        //check if owner recieves amount
        assertEq(address(owner).balance,0.5 ether);
        // //check if user balance is decreased and correctly charged
        assertEq(address(user).balance,1.5 ether);
    }

     //test for bike nft with wrong price
    function testbuyWrongPrice() public {
        //start interaction as owner
        vm.startPrank(owner);
        //minting nft 
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.displayBikeForSale(owner,1,400000000000000000);
        //check if owner is correct after the mint
        assertEq(nft_contract.ownerOf(1),owner);
        //check if the bike price is correct
        assertEq(nft_contract.bikePrice(1),400000000000000000);
        //interaction stop
        vm.stopPrank();
        //starting interactioon as address(3)
        vm.startPrank(address(3));
        //giving 3 ether to address 3
        vm.deal(address(3),2 ether);
        //worng price to be reverted
        vm.expectRevert("Low Balance");
        //buying at low price than original
        nft_contract.buyBike{value:0.3 ether}(address(3),1);
    }
    
    //test for bike return with price change after mint price
    function testrentBikeWithReturePriceChange()public{
        //start interaction as owner
        vm.startPrank(owner);
        //minting nft 
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //changing price after nft mint
        nft_contract.changeRentPrice(owner,200000000000000000,1);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike
         nft_contract.rentaBike(user,1,1692092111);
        //check if bike is rented to user 
         assertEq(nft_contract.rentedNFT(1),user);
        //check if starting time is correct or not
         assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
        //check if owner recieved the amount
        assertEq(address(owner).balance,0.2 ether);
        //check if user balance is deducted correctly
        assertEq(address(user).balance,1.8 ether);
    }

        //test for rent bike with return where starttime is more than end time
    function testrentBikeWithRetureWithstartTimegreaterthanEnd()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftForRent(1),true);
        //starting interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentaBike(user,1,1692092113);
        //check if bike is rented by user or not
        assertEq(nft_contract.rentedNFT(1),user);
        //revert if time is mismatched and less than
        vm.expectRevert("Start time must be less than end time");
        //nft return with start time greature than end time
        nft_contract.returnaBike{value:1 ether}(user,1692092111,1);
        //check if user balance is same and is not charged
        assertEq(address(user).balance,2 ether);
    }

        //check if test rent bike with start and endtime saem
    function testrentBikeWithRetureWithsameTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //stops interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftForRent(1),true);
        //interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentaBike(user,1,1692092111);
        //check if nft is rented by user or not
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time for a user is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //revert if and end time are same
        vm.expectRevert("Start and End Time Cannot be the same");
        //return bike with same time as start time
        nft_contract.returnaBike{value:1 ether}(user,1692092111,1);
        //check if user balance is same and is not charged
        assertEq(address(user).balance,2 ether);
    }


    //test for rent bike with return (but end time is zero)
     function testrentBikeWithRetureWithZeroEndTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //stops interaction as owner
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentaBike(user,1,1692092111);
        //check if bike is rented by correct user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct
        assertEq(nft_contract.startTime(user),1692092111);
        //revert if end time is zero 
        vm.expectRevert("End time cannot be zero");
        //return bike with payment but zero end time
        nft_contract.returnaBike{value:1 ether}(user,0,1);
        //check if user balance is intact
        assertEq(address(user).balance,2 ether);
    }

        //test for return with zero tokenId
    function testrentBikeWithRetureWithZeroTokenId()public{
        //starting to interact as owner
        vm.startPrank(owner);
        //start minting nft and setting price
        nft_contract.safeMint(owner,"abc");
        //listing nft for rent
        nft_contract.listForRent(owner,1,400000000000000000);
        //interation stop
        vm.stopPrank();
        //Check if nft is listed for the rent
        assertEq(nft_contract.nftForRent(1),true);
         //starting to interact as user
        vm.startPrank(user);
        //calling rent Function
        nft_contract.rentaBike(user,1,1692092111);
        //checkif nft is rented by the same user 
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is same or not
        assertEq(nft_contract.startTime(user),1692092111);
        //revert the Bike does not exist when returning 0 tokenId
        vm.expectRevert("Bike doesnot Existed");
        //return bike call for nft to be reverted
        nft_contract.returnaBike{value:1 ether}(user,1692093911,0);
        //check if the balance is intact and is not being used.
        assertEq(address(user).balance,2 ether);
    }

        //test for return bike with zero address
    function testrentBikeWithRetureWithZeroAddress()public{
        //start interaction as owner
        vm.startPrank(owner);
        //start minting nft and setting price
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting  
        nft_contract.listForRent(owner,1,400000000000000000);
        //interation stop
        vm.stopPrank();
        //check if nft is listed for rent
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike
        nft_contract.rentaBike(user,1,1692092111);
        //check if bike is rented by the same user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start address is same as user
        assertEq(nft_contract.startTime(user),1692092111);
        //expected revert for zero address
        vm.expectRevert("Cannot Rent to zero Address");
        //return bike with zero address
        nft_contract.returnaBike{value:1 ether}(address(0),1692093911,1);
        //check if balance is intact
        assertEq(address(user).balance,2 ether);
    }
    
        //test for return without rent or active ride
    function testbikeReturnWithoutactiveRide() public{
        //start interaction as user
        vm.startPrank(user);
        //expected revert without rent
        vm.expectRevert("You haven't rented a bike");
        //contract call to return bike without rent
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
    }

        //test for renting same bike twice 
    function testRentsameBikeTwice()public{
        //start interaction as owner
        vm.startPrank(owner);
        
        //mint nft to the owner
        nft_contract.safeMint(owner,"abc");
        
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        
        //stop interaction as owner
        vm.stopPrank();

        //check if nft is rented for the the 
        assertEq(nft_contract.nftForRent(1),true);
        
        //interaction to set as user
        vm.startPrank(user);

        //rent a listed bike by user
        nft_contract.rentaBike(user,1,1692092111);

        //check if user has rented the bike
        assertEq(nft_contract.rentedNFT(1),user);

        //start interaction as user address 3
        vm.startPrank(address(3));

        //call to be reverted bike already rented
        vm.expectRevert("You cannot rent this bike already Rented");

        //nft contract address 3 is calling rent on rented Bike
        nft_contract.rentaBike(address(3),1,1692092111);
    }

        //test cannot rent with start time as zero
    function testcannotRentWithZeroStartTime()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero starttime
        vm.expectRevert("Start time cannot be zero");
          //calls rent with zero starttime
        nft_contract.rentaBike(user,1,0);
    }

        //test cannot rent the zero tokenId
    function testcannotRentWithZeroTokenID()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero tokenId
        vm.expectRevert("Bike doesnot Existed");
         //calls rent with zero tokenId
        nft_contract.rentaBike(user,0,1692092111);
    }

        //test for minted nft but not listed for rent to check if they can be rented
     function testcannotRentWithZeroAddress()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint the nft with price
        nft_contract.safeMint(owner,"abc");
       //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //ineraction stops
        vm.stopPrank();
        //interaction start as user to rent
        vm.startPrank(user);
        //to be reverted with zero address
        vm.expectRevert("Cannot Rent to zero Address");
        //calls rent with zero address
        nft_contract.rentaBike(address(0),1,1692092111);
    }


     //test for bike cannot be transfer when rented
    function testrentedBikeCannotBeTransfer()public{
        //start interaction as owner
        vm.startPrank(owner);
        //mint nft for rent
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //check if nft is listed or not
        assertEq(nft_contract.nftForRent(1),true);
        //rent bike as user
        nft_contract.rentaBike(user,1,1692092111);
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
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.listForRent(owner,1,400000000000000000);
        //stopping interaction
        vm.stopPrank();
        //check if nft is listed or not
        assertEq(nft_contract.nftForRent(1),true);
        //start interaction as user
        vm.startPrank(user);
        //rent a bike as user
        nft_contract.rentaBike(user,1,1692092111);
        //check if bike is rented by correct user
        assertEq(nft_contract.rentedNFT(1),user);
        //check if start time is correct or not
        assertEq(nft_contract.startTime(user),1692092111);
        //return bike with payment
        nft_contract.returnaBike{value:1 ether}(user,1692093911,1);
        //check if owner balance is increased 
        assertEq(address(owner).balance,0.4 ether);
        //check is user balance is decreased. 
        assertEq(address(user).balance,1.6 ether);
        //start interaction as owner
        vm.startPrank(owner);
        nft_contract.removefromrented(owner,1);
        //trasferring nft to address 3
        nft_contract.transferFrom(owner,address(3),1);
        //check if nft is transferred and owner is updated.
        assertEq(nft_contract.ownerOf(1),address(3));
    }


    //test for bike listed cannot be transfer
    function testsellButcannotbeTransferred() public {
       //start interaction as owner
        vm.startPrank(owner);
        //minting nft 
        nft_contract.safeMint(owner,"abc");
        //list the NFT for renting
        nft_contract.displayBikeForSale(owner,1,400000000000000000);
        //check if owner is owner
        assertEq(nft_contract.ownerOf(1),owner);
        //check if price is correct
        assertEq(nft_contract.bikePrice(1),400000000000000000);
        //stops interaction
        vm.stopPrank();
        //start interaction as owner to transfer nft
        vm.startPrank(owner);
        vm.expectRevert("Transfer not allowed");
        //transfering nft token listed for selling
        nft_contract.transferFrom(owner,user, 1);
    }
}