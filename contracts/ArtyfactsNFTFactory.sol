// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ArtyfactsNFT.sol";


contract ArtyfactsNFTFactory is Ownable {

    address public immutable proxyImplementation;
    IERC721 public earlyAccessPass;
    uint256 public maxAllowedAmount = 50 ether; // launch for free if your collection collects less than this amount

    // bitmask params
    uint32 constant SHOULD_START_AT_ONE = 1 << 1;
    uint32 constant SHOULD_START_SALE = 1 << 2;
    uint32 constant SHOULD_LOCK_PAYOUT_CHANGE = 1 << 3;

    event NFTCreated(
        address deployedAddress,
        // creation parameters
        uint256 price,
        uint256 maxSupply,
        uint256 nReserved,
        string name,
        string symbol,
        bool shouldUseJSONExtension,
        bool shouldStartAtOne,
        bool shouldStartSale,
        bool shouldLockPayoutChange

    );

    modifier hasAccess(address creator) {
        // check that creator owns NFT
        require(address(earlyAccessPass) == address(0) || earlyAccessPass.balanceOf(msg.sender) > 0, "ArtyfactsNFTFactory: Early Access Pass is required");
        _;
    }

    modifier checkTotalAmount(uint256 amount) {
        require(amount < maxAllowedAmount, "ArtyfactsNFTFactory: Collection total amount is too high");
        _;
    }

    constructor(address _earlyAccessPass) {
        proxyImplementation = address(new ArtyfactsNFT());

        earlyAccessPass = IERC721(_earlyAccessPass);

        emit NFTCreated(
            proxyImplementation,
            0,
            0,
            0,
            "IMPLEMENTATION",
            "IMPLEMENTATION",
            false,
            false,
            false,
            false
        );
    }

    function updateEarlyAccessPass(address _earlyAccessPass) public onlyOwner {
        earlyAccessPass = IERC721(_earlyAccessPass);
    }

    function updateMaxAllowedAmount(uint256 _maxAllowedAmount) public onlyOwner {
        maxAllowedAmount = _maxAllowedAmount;
    }

    function createNFT(
        uint256 _startPrice,
        uint256 _maxSupply,
        uint256 _nReserved,
        uint256 _maxTokensPerMint,
        uint256 _royaltyFee,
        string memory _uri,
        string memory _name, string memory _symbol
    ) external hasAccess(msg.sender) {

        address clone = Clones.clone(proxyImplementation);

        ArtyfactsNFT(payable(clone)).initialize(
            _startPrice,
            _maxSupply,
            _nReserved,
            _maxTokensPerMint,
            _royaltyFee,
            _uri,
            _name, _symbol,
            false
        );

        ArtyfactsNFT(payable(clone)).transferOwnership(msg.sender);

        emit NFTCreated(
            clone,
            _startPrice,
            _maxSupply,
            _nReserved,
            _name,
            _symbol,
            false,
            false,
            false,
            false
        );

    }

    function createNFTWithSettings(
        uint256 _startPrice,
        uint256 _maxSupply,
        uint256 _nReserved,
        uint256 _maxTokensPerMint,
        uint256 _royaltyFee,
        string memory _uri,
        string memory _name, string memory _symbol,
        address payoutReceiver,
        bool shouldUseJSONExtension,
        uint16 miscParams
    ) external hasAccess(msg.sender) {

        address clone = Clones.clone(proxyImplementation);

        // params is a bitmask of:

        // bool shouldUseJSONExtension = (miscParams & 0x01) == 0x01;
        // bool startTokenIdAtOne = (miscParams & 0x02) == 0x02;
        // bool shouldStartSale = (miscParams & 0x04) == 0x04;
        // bool shouldLockPayoutChange = (miscParams & 0x08) == 0x08;

        ArtyfactsNFT(payable(clone)).initialize(
            _startPrice,
            _maxSupply,
            _nReserved,
            _maxTokensPerMint,
            _royaltyFee,
            _uri,
            _name, _symbol,
            miscParams & SHOULD_START_AT_ONE != 0
        );

        if (shouldUseJSONExtension) {
            ArtyfactsNFT(payable(clone)).setPostfixURI(".json");
        }

        if (miscParams & SHOULD_START_SALE != 0) {
            ArtyfactsNFT(payable(clone)).startSale();
        }

        if (payoutReceiver != address(0)) {
            ArtyfactsNFT(payable(clone)).setPayoutReceiver(payoutReceiver);
        }

        if (miscParams & SHOULD_LOCK_PAYOUT_CHANGE != 0) {
            ArtyfactsNFT(payable(clone)).lockPayoutChange();
        }

        ArtyfactsNFT(payable(clone)).transferOwnership(msg.sender);
 
        emit NFTCreated(
            clone,
            _startPrice,
            _maxSupply,
            _nReserved,
            _name,
            _symbol,
            shouldUseJSONExtension,
            miscParams & SHOULD_START_AT_ONE != 0,
            miscParams & SHOULD_START_SALE != 0,
            miscParams & SHOULD_LOCK_PAYOUT_CHANGE != 0
        );
    }

    function createNFTWithoutAccessPass (
        uint256 _startPrice,
        uint256 _maxSupply,
        uint256 _nReserved,
        uint256 _maxTokensPerMint,
        uint256 _royaltyFee,
        string memory _uri,
        string memory _name, string memory _symbol,
        address payoutReceiver,
        bool shouldUseJSONExtension,
        uint16 miscParams
    ) external checkTotalAmount(_startPrice * _maxSupply) {

        address clone = Clones.clone(proxyImplementation);

        // params is a bitmask of:

        // bool shouldUseJSONExtension = (miscParams & 0x01) == 0x01;
        // bool startTokenIdAtOne = (miscParams & 0x02) == 0x02;
        // bool shouldStartSale = (miscParams & 0x04) == 0x04;
        // bool shouldLockPayoutChange = (miscParams & 0x08) == 0x08;

        ArtyfactsNFT(payable(clone)).initialize(
            _startPrice,
            _maxSupply,
            _nReserved,
            _maxTokensPerMint,
            _royaltyFee,
            _uri,
            _name, _symbol,
            miscParams & SHOULD_START_AT_ONE != 0
        );

        if (shouldUseJSONExtension) {
            ArtyfactsNFT(payable(clone)).setPostfixURI(".json");
        }

        if (miscParams & SHOULD_START_SALE != 0) {
            ArtyfactsNFT(payable(clone)).startSale();
        }

        if (payoutReceiver != address(0)) {
            ArtyfactsNFT(payable(clone)).setPayoutReceiver(payoutReceiver);
        }

        if (miscParams & SHOULD_LOCK_PAYOUT_CHANGE != 0) {
            ArtyfactsNFT(payable(clone)).lockPayoutChange();
        }

        ArtyfactsNFT(payable(clone)).transferOwnership(msg.sender);
 
        emit NFTCreated(
            clone,
            _startPrice,
            _maxSupply,
            _nReserved,
            _name,
            _symbol,
            shouldUseJSONExtension,
            miscParams & SHOULD_START_AT_ONE != 0,
            miscParams & SHOULD_START_SALE != 0,
            miscParams & SHOULD_LOCK_PAYOUT_CHANGE != 0
        );
    }
}
