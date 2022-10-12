// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC721 {
    function transferFrom (
        address _from,
        address _to,
        uint _nftId
    ) external;
}

contract DutchAuction {
    uint private constant Duration = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice; 
    uint public immutable startsAt;
    uint public immutable expiresAt;
    uint public immutable discountRate;

    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startsAt = block.timestamp;
        expiresAt = block.timestamp + Duration;

        require(
            _startingPrice >= _discountRate * Duration, 
            "starting price < discount"
        );

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns(uint) {
        uint timeElapsed = block.timestamp - startsAt;
        uint discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "Auction expired");

        uint price = getPrice();
        require(msg.value >= price, "ETH < Price");

        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        selfdestruct(seller);
    }
}

