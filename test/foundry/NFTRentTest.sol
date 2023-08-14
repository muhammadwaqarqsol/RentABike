// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "../../contracts/NFTRent.sol";

// contract MarketTest is Test {

//     using OrderTypes for OrderTypes.MakerOrder;
//     using OrderTypes for OrderTypes.TakerOrder;

//     NFTMarket public _contract;
//     NFT public nft_contract;

//     uint256 internal makerPrivateKey;
//     address internal maker;

//     uint256 internal takerPrivateKey;
//     address internal taker;

//     event testAddress (address);
//     event testMakerOrder (OrderTypes.MakerOrder);
//     event testTakerOrder (OrderTypes.TakerOrder);

//     OrderTypes.MakerOrder public tempMakerOrder;

//     function setUp() public {
//         _contract = new NFTMarket();
//         nft_contract = new NFT(address(_contract));

//         makerPrivateKey = 0xA11CE;
//         maker = vm.addr(makerPrivateKey);
        
//         takerPrivateKey = 0xB0B;
//         taker = vm.addr(takerPrivateKey);

//         vm.deal(taker, 2 ether);

//         //create a token in nft contract
//         vm.prank(maker);
//         nft_contract.createToken("some uri");

//         //create a maker bid
//         sign();

//         //create a taker bid
//     }

//     function testInitial() public {
//         assertEq(nft_contract.contractAddress(), address(_contract));
//         assertEq(nft_contract.ownerOf(1), maker);
//         assertEq(nft_contract.balanceOf(maker), 1);
//     }

//     function testBuying() public {
//         emit testAddress(taker);
//         emit testAddress(maker);
//         emit testAddress(address(this));
//         uint256 oldBal = address(this).balance;
//         vm.startPrank(taker);
//         OrderTypes.TakerOrder memory takerOrder = OrderTypes.TakerOrder(false, taker, 0.3 ether, 1, 9000);
//         emit testTakerOrder(takerOrder);
//         _contract.matchAskWithTakerBid{value: 0.3 ether}(takerOrder, tempMakerOrder);
//         vm.stopPrank();

//         assertEq(nft_contract.ownerOf(1), taker);
//         assertEq(address(maker).balance, 0.2 ether);
//         assertEq(address(this).balance, oldBal + 0.1 ether);
//     }

//     function sign() public returns (uint8 v, bytes32 r, bytes32 s) {
//         OrderTypes.MakerOrder memory makerOrder = OrderTypes.MakerOrder(true, maker, maker, address(nft_contract), 0.2 ether, 1, 0.1 ether, 6, 0, 0x00, 0x00);
//         bytes32 digest = getTypedDataHash(makerOrder);
//         vm.prank(maker);
//         // emit testAddress(maker);
//         (v, r, s) = vm.sign(makerPrivateKey, digest);
//         makerOrder.v = v;
//         makerOrder.r = r;
//         makerOrder.s = s;
//         tempMakerOrder = makerOrder;
//         emit testMakerOrder(makerOrder);
//     }

//     function getStructHash(OrderTypes.MakerOrder memory makerOrder) internal pure returns (bytes32) {
//         return
//             keccak256(
//                 abi.encode(
//                     MakerOrder_TYPEHASH,
//                     makerOrder.isOrderAsk,
//                     makerOrder.signer,
//                     makerOrder.nftContract,
//                     makerOrder.baseAccount,
//                     makerOrder.price,
//                     makerOrder.nonce,
//                     makerOrder.tokenId
//                 )
//             );
//     }

//     function getTypedDataHash(OrderTypes.MakerOrder memory makerOrder) public view returns (bytes32) {
//         return
//             keccak256(
//                 abi.encodePacked(
//                     "\x19\x01",
//                     domainHash(),
//                     getStructHash(makerOrder)
//                 )
//             );
//     }

//     bytes32 public constant MakerOrder_TYPEHASH = keccak256("ListNFT(bool IsOrderAsk,address sender,address collection,address baseAccount,uint price,uint nonce,uint tokenId)");

//     function domainHash() internal view returns(bytes32) {
//         bytes32 hash = keccak256(
//             abi.encode(
//                 keccak256(
//                     "EIP712Domain(string name,string version,address verifyingContract)"
//                 ),
//                 keccak256(bytes("MarketPlace")),
//                 keccak256(bytes("1")),
//                 address(_contract)
//             )
//         );
//         return hash;
//     }

//     fallback () external payable {}
//     receive () external payable {}
// }