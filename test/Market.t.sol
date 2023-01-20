// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import 'contracts/NFT.sol';
import 'contracts/NFTMarket.sol';

contract NftMarketTest is Test {
    NFT nft;
    NFTMarket nftmarket;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        address donationAddress;
        uint256 donationPer;
        uint256 royaltyPer;
        uint256 tokenId;
        uint256 minPrice;
        address creator;
        address owner;
        uint256 price;
        bool isActive;
    }
    
    // Note: Setup is run before every function
    function setUp() public {
        vm.startPrank(address(0x2e17331cAFAbABAF1abfc2d1Fd37aD48d7dAD929));
        nftmarket =  new NFTMarket();
        nft = new NFT(address(nftmarket));   
        vm.stopPrank();     
    }

    //True Test Case
    function test_creatNft() public {
        vm.startPrank(address(0x1));
        nft.createToken("abc");
        
        assertEq(nft.ownerOf(1),address(0x1));
        assertEq( nft.tokenURI(1), "abc" );
    }

    function test_createMarketItem() public {
        vm.startPrank(address(0x1));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        ( uint256 itemId, , , , , , , , address owner, uint256 price,bool isActive ) = nftmarket.idToMarketItem(1);

        vm.stopPrank();

        assertEq(owner,address(0x1));
        assertEq(itemId,1);
        assertEq(price,10000000000000000);
        assertEq(isActive,true);
    }

    function test_butItem() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        vm.stopPrank();
        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C));
        vm.deal(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C), 2 ether);

        nftmarket.createMarketSale{value: 0.0102 ether}(
            address(nft),
            1
        );

        ( , , , , , , , ,address owner, , bool isActive ) = nftmarket.idToMarketItem(1);

        assertEq(false,isActive);
        assertEq(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C),owner);
        assertEq(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf).balance,9800000000000000);
        assertEq(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C).balance,1989800000000000000);
        assertEq(address(0x2e17331cAFAbABAF1abfc2d1Fd37aD48d7dAD929).balance,400000000000000);
    }

    function test_butItemByOffer() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        vm.stopPrank();
        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C));
        vm.deal(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C), 2 ether);

        nftmarket.offerMarketSale{value: 0.0204 ether}(
            address(nft),
            1,
            20000000000000000
        );

        ( , , , , , , , ,address owner, , bool isActive ) = nftmarket.idToMarketItem(1);

        assertEq(false,isActive);
        assertEq(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C),owner);
        // assertEq(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf).balance,9800000000000000);
        // assertEq(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C).balance,1989800000000000000);
        // assertEq(address(0x2e17331cAFAbABAF1abfc2d1Fd37aD48d7dAD929).balance,400000000000000);
    }

    function test_unlistItem() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        nftmarket.unlistItem(1);

        ( , , , , , , , , , , bool isActive ) = nftmarket.idToMarketItem(1);

        assertEq(isActive,false);
    }

    function test_listItemAfterUnlist() public {
         vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        nftmarket.unlistItem(1);

        nftmarket.listItem(address(nft), address(0), 0, 0, 1, 10000000000000000);

        ( , , , , , , , , , , bool isActive) = nftmarket.idToMarketItem(1);

        assertEq(isActive,true);
    }

    function test_listItemAfterBuy() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        vm.stopPrank();
        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C));
        vm.deal(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C), 2 ether);

        nftmarket.createMarketSale{value: 0.0102 ether}(
            address(nft),
            1
        );

        nft.setApprovalForAll(address(nftmarket),true);
        nftmarket.listItem(address(nft), address(0), 0, 0, 1, 10000000000000000);

        ( , , , , , , , , address owner, , bool isActive ) = nftmarket.idToMarketItem(1);

        assertEq(owner,address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C));
        assertEq(isActive,true);
    }

    //False Test Case
    function test_falseCreateNft() public {
        vm.startPrank(address(0));
        vm.expectRevert(bytes("Sender has zero Address"));
        nft.createToken("abc");
    }

    function test_FalseCreateMarketItem() public {
        vm.startPrank(address(0x1));
        nft.createToken("abc");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.expectRevert(bytes("Sender is not the owner of NFT"));
        // Sender is not the owner of NFT
        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        vm.stopPrank();
    }

    function test_falseBuyItem() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        nft.createToken("abc");

        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        vm.deal(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf), 2 ether);
        vm.expectRevert(bytes("Sender is not the owner"));
        
        nftmarket.createMarketSale{value: 0.0102 ether}(
            address(nft),
            1
        );

        vm.stopPrank();
        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C));
        vm.deal(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C), 2 ether);

        vm.expectRevert(bytes("Please make the price to be same as listing price"));
        
        nftmarket.createMarketSale{value: 0.01 ether}(
            address(nft),
            1
        );
    }

    function test_FalseUnListItem() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        
        // Create NFT
        nft.createToken("abc");

        // Create Market Item
        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );
        vm.stopPrank(); 

        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C)); // change msg.sender
        // False : Revert "Only owner can List thier item"
        vm.expectRevert(bytes("Only owner can List thier item"));
        nftmarket.unlistItem(1);
        vm.stopPrank();

        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        // Test Case 2
        nftmarket.unlistItem(1);
        // False : Revert "Item is already Listed"
        vm.expectRevert(bytes("Item is already not Listed"));
        nftmarket.unlistItem(1);
        vm.stopPrank();        
    }

    function test_FalseListItem() public {
        vm.startPrank(address(0x705AB4299e154C6e85E0Ca2E1127bE5784D6DDdf));
        
        // Create NFT
        nft.createToken("abc");

        // Create Market Item
        nftmarket.createMarketItem(
            address(nft),
            address(0),
            0,
            0,
            1,
            0,
            10000000000000000,
            true
        );

        // False : Revert "Item is already Listed"
        vm.expectRevert(bytes("Item is already Listed"));
        nftmarket.listItem(address(nft), address(0), 0, 0, 1, 10000000000000000);
        nftmarket.unlistItem(1);
        vm.stopPrank(); 

        vm.startPrank(address(0xfC8b39Bb598071526BDA64D5f26790C8DE4F2e3C)); // change msg.sender
        
        // False : Revert "Only owner can List thier item"
        vm.expectRevert(bytes("Only owner can List thier item"));
        nftmarket.listItem(address(nft), address(0), 0, 0, 1, 10000000000000000);
    }
}