// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../contracts/NFTRent.sol";

contract BikeRentTest is Test {

    Rentabike public nft_contract;

    uint256 internal ownerPrivateKey;
    address internal owner;
    
    uint256 internal userPrivateKey;
    address internal user;

    function setUp() public {
        nft_contract = new Rentabike();

        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        userPrivateKey = 0xB0B;
        user = vm.addr(userPrivateKey);

        nft_contract.transferOwnership(owner);

        vm.deal(user, 2 ether);
    }

    function testInitial() public {
        assertEq(nft_contract.balanceOf(owner), 0);
    }

    function testmintNFt() public {
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        assertEq(nft_contract.ownerOf(1), owner);
        assertEq(nft_contract.totalSupply(),1);
    }

     function testmintNFtZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Cannot Mint to zero address");
        nft_contract.safeMint(address(0),"abc");
        vm.expectRevert("URI cannot be empty");
        nft_contract.safeMint(owner,"");
        vm.stopPrank();
    }

    function testRentBikeWithList()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.nftListed(1),true);
    }

    function testcannotRentWithOutListing()public{
         vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),false);
        vm.startPrank(user);
        vm.expectRevert("You cannot rent the bike");
        nft_contract.rentBike(user,1,1692092111);
    }

     function testcannotRentWithZeroAddress()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),false);
        vm.startPrank(user);
        vm.expectRevert("You cannot rent the bike");
        nft_contract.rentBike(user,1,1692092111);
    }

    function testcannotRentWithZeroTokenID()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),false);
        vm.startPrank(user);
        vm.expectRevert("Bike doesnot Existed");
        nft_contract.rentBike(user,0,1692092111);
    }

    function testcannotRentWithZeroStartTime()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),false);
        vm.startPrank(user);
        vm.expectRevert("Start time cannot be zero");
        nft_contract.rentBike(user,1,0);
    }

     function testRentsameBikeTwice()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(address(3));
        vm.expectRevert("You cannot rent this bike already Rented");
        nft_contract.rentBike(address(3),1,1692092111);
    }

    function testbikeReturnWithoutactiveRide() public{
        vm.startPrank(user);
        vm.expectRevert("You haven't rented a bike");
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
    }

    function testrentBikeWithRetureWithZeroAddress()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        vm.expectRevert("Cannot Rent to zero Address");
        nft_contract.returnBike{value:1 ether}(address(0),1692093911,1);
        assertEq(address(user).balance,2 ether);
    }

     function testrentBikeWithRetureWithZeroTokenId()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
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
        nft_contract.safeMint(owner,"abc");
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
        nft_contract.safeMint(owner,"abc");
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
        nft_contract.safeMint(owner,"abc");
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
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        assertEq(address(owner).balance,0.5 ether);
        assertEq(address(user).balance,1.5 ether);
    }
    

    function testrentedBikeCannotBeTransfer()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
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
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        vm.stopPrank();
        assertEq(nft_contract.nftListed(1),true);
        vm.startPrank(user);
        nft_contract.rentBike(user,1,1692092111);
        assertEq(nft_contract.rentedNFT(1),user);
        assertEq(nft_contract.startTime(user),1692092111);
        nft_contract.returnBike{value:1 ether}(user,1692093911,1);
        assertEq(address(owner).balance,0.5 ether);
        assertEq(address(user).balance,1.5 ether);
        vm.startPrank(owner);
        nft_contract.transferFrom(owner,address(3),1);
        assertEq(nft_contract.ownerOf(1),address(3));
    }

     function testrentBikeWithReturePriceChange()public{
        vm.startPrank(owner);
        nft_contract.safeMint(owner,"abc");
        nft_contract.listNFT(1);
        nft_contract.changePrice(20);
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

  
}