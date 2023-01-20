// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // security for non-reentrant
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTMarket is ReentrancyGuard,AccessControl  {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; // Id for each individual item
    Counters.Counter private _itemsSold; // Number of items sold

    address public owner;
    uint256  public feePercent;

    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    constructor() {
        owner = msg.sender;
        _setupRole(MEMBER_ROLE, msg.sender);
        feePercent = 200;
    }
    // modifier : check who is only member of marketplace
    modifier onlyMember() {
        require(isMember(msg.sender), "Restricted to members.");
        _;
    }
    // get marketItem from its id
    mapping(uint256 => MarketItem) public idToMarketItem;
    // Struct of Market Item Created
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        address donationAddress;
        uint donationPer;
        uint256 royaltyPer;
        uint256 tokenId;
        uint256 minPrice;
        address creator;
        address owner;
        uint256 price;
        bool isActive;
    }
    // Event of Market Item Created
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        address donationAddress,
        uint256 donationPer,
        uint256 royaltyPer,
        uint256 indexed tokenId,
        uint256 minPrice,
        address creator,
        address owner,
        uint256 price,
        bool isActive
    );
    // Event Bought Market Item
    event BoughtMarketItem(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address creator,
        address owner
    );

    // Return true if the `account` belongs to the community.
    function isMember (
        address account
    ) public virtual view returns (bool) {
        return hasRole(MEMBER_ROLE, account);
    }
    
    //addMember
    /*
     * address @onlyMember cadd the member.
     * Function should be perform by only member of the marketplace.
    */
    function addMember (
        address account
    ) public virtual onlyMember {
        _setupRole(MEMBER_ROLE, account);
    }
    //revokeMember
    /*
     * address @onlyMember can revoke the member.
     * Function should be perform by only member of the marketplace.
    */
    function revokeMember (
        address account
    ) public virtual onlyMember {
        _revokeRole(MEMBER_ROLE, account);
    }
    //setFees
    /*
     * address @onlyMember can set the fees.
     * Function should be perform by only member of the marketplace.
    */
    function setFees (
        uint _feePercent
    ) public virtual onlyMember {
        feePercent = _feePercent;
    }
    //createMarketItem
    /*
     * address @creator create the be marketItem.
     * Function should be perform by NFT owner.
    */
    function createMarketItem (
        address nftContract,
        address donationAdress,
        uint256 donationPer,
        uint256 royaltyPer,
        uint256 tokenId,
        uint256 minPrice,
        uint256 price,
        bool isActive
    ) public nonReentrant {
        require(price >= 0, "Item should not be less than zero");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender,"Sender is not the owner of NFT");
        //inrement current item id
        _itemIds.increment();
        //get current merchant id
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            donationAdress,
            donationPer,
            royaltyPer,
            tokenId,
            minPrice,
            msg.sender,
            msg.sender, // No owner for the item
            price,
            isActive
        );
        // trigger the event
        emit MarketItemCreated(
            itemId,
            nftContract,
            donationAdress,
            donationPer,
            royaltyPer,
            tokenId,
            minPrice,
            msg.sender,
            msg.sender,
            price,
            isActive
        );
    }
    // createMarketSale (Buy on fixed price)
    /*
     * address @buyer create the be MarketSale.
     * Function should be perform by who wants to buy the NFT.
    */
    function createMarketSale(
       address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint256 price = idToMarketItem[itemId].price;
        uint256 feeCommision = getPerAmount(price,feePercent);
        uint totalPrice = price + feeCommision;

        require(msg.value >= totalPrice,"Please make the price to be same as listing price");

        proceedToTransfer(nftContract,price,feeCommision,itemId);        
    }
    //offerMarketSale (Buy on offer price)
    /*
     * address @buyer create the be OfferSale.
     * Function should be perform by who wants to buy the NFT.
    */
    function offerMarketSale(
        address nftContract, 
        uint256 itemId,
        uint256 _nftPrice
    ) public payable nonReentrant {

        uint256 minPrice = idToMarketItem[itemId].minPrice;     
        uint256 feeCommision = getPerAmount(_nftPrice,feePercent);
        uint256 offerPrice = msg.value - feeCommision;
    
        require(offerPrice >= minPrice,"Price should be greater than min price");
        
        proceedToTransfer(nftContract,_nftPrice,feeCommision,itemId);
    }
    //unlistItem
    /*
     * address @ownerofNFT should unlist the item.
     * Function should be perform by the NFT owner.
    */
    function unlistItem (
        uint _itemId
    ) public nonReentrant {
        require(idToMarketItem[_itemId].isActive,"Item is already not Listed");
        require(idToMarketItem[_itemId].owner == msg.sender,"Only owner can List thier item");
        idToMarketItem[_itemId].isActive = false;
    }
    //listItem
    /*
     * address @ownerofNFT should list the item.
     * Function should be perform by the NFT owner.
    */
    function listItem (
        address nftContract,
        address _donationAdress,
        uint256 _donationPer,
        uint256 _minPrice,
        uint _itemId,
        uint256 _price
    ) public nonReentrant {
        require(IERC721(nftContract).isApprovedForAll(idToMarketItem[_itemId].owner, address(this)),"Approval is not given");
        require(!idToMarketItem[_itemId].isActive,"Item is already Listed");
        require(idToMarketItem[_itemId].owner == msg.sender,"Only owner can List thier item");
        require(_price >= 0, "Price is less than zero");
        require(_minPrice >= 0, "Minimum Price is less than zero");
        
        idToMarketItem[_itemId].price = _price;
        idToMarketItem[_itemId].minPrice = _minPrice;
        idToMarketItem[_itemId].isActive = true;
        idToMarketItem[_itemId].donationAddress = payable(_donationAdress);
        idToMarketItem[_itemId].donationPer = _donationPer;
    }
    //get amount
    /*
     * should return the calculated amount
     * Function should be perform internally.
    */
    function getPerAmount(
        uint _price,
        uint _amountPer
    ) internal pure returns(uint) {
        return ((_price * _amountPer)/10000);
    }
    //proceed To Transfer
    /*
     * transafer amount and nft
     * Function should be perform internally.
    */
    function proceedToTransfer(
        address nftContract,
        uint price,
        uint feeCommision,
        uint itemId
    ) public payable {
        require(idToMarketItem[itemId].isActive,"Item is not listed");
        require(idToMarketItem[itemId].owner != msg.sender,"Sender is not the owner");

        uint256 totalPrice = price - feeCommision;
        
        address donationAddress = idToMarketItem[itemId].donationAddress;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        //transfer fee commision to owner.
        payable(owner).transfer(feeCommision * 2);
        // calculation and transfer amount for donation
        if (donationAddress != address(0) && idToMarketItem[itemId].donationPer > 0 ) {
            uint256 donation = getPerAmount(price, idToMarketItem[itemId].donationPer);
            payable(donationAddress).transfer(donation);
            totalPrice = totalPrice - donation;
        }
        
        if (idToMarketItem[itemId].creator != idToMarketItem[itemId].owner && idToMarketItem[itemId].royaltyPer != 0) {
            uint256 royaltyAmount = getPerAmount(price,idToMarketItem[itemId].royaltyPer);
            payable(idToMarketItem[itemId].creator).transfer(royaltyAmount);
            totalPrice = totalPrice - royaltyAmount;
        }

        //transfer the price of NFT to owner
        payable(idToMarketItem[itemId].owner).transfer(totalPrice);
        // transfer NFT from owner to buyer
        IERC721(nftContract).transferFrom(idToMarketItem[itemId].owner, msg.sender, tokenId);
        // listNFT change to false
        idToMarketItem[itemId].isActive = false;
        // change owner in struct
        idToMarketItem[itemId].owner = msg.sender;
        // trigger the event
        emit BoughtMarketItem(
            itemId,
            nftContract,
            tokenId,
            price,
            idToMarketItem[itemId].owner,
            msg.sender
        );
    }
}
