// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OurNFTContract is ERC721, ERC721URIStorage, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    VRFCoordinatorV2Interface COORDINATOR;

    
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  2;

    struct NFTStat {
        bool exists;
        address originalOwner;
        address currentOwner;
        string characterName;
        uint8 power;
        uint8 specialPower;
        uint16 cooldown;
    }

    mapping(uint256 => string) requestToCharacterName;
    mapping(uint256 => address) requestToSender;

    Counters.Counter private _tokenIdCounter;


    mapping(uint256 => NFTStat) private characterRegistry;

    constructor(uint64 _subscriptionId) ERC721("OurNFTContract", "ONC") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
    }

    // function safeMint(address to, string memory uri) public onlyOwner {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }

    // Assumes the subscription is funded sufficiently.
    function safeMint(string calldata name) public {
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        requestToCharacterName[requestId] = name;
        requestToSender[requestId] = msg.sender;
    }
    
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {

        address sender = requestToSender[requestId];
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(sender, tokenId);
        characterRegistry[tokenId] = NFTStat(
            true,
            sender,
            sender,
            requestToCharacterName[requestId],
            0,
            0,
            0
            );

        // s_randomWords = randomWords;
    }
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        characterRegistry[tokenId].currentOwner = to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, "");
        characterRegistry[tokenId].currentOwner = to;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require( _isApprovedOrOwner(_msgSender(), tokenId),"Not Permitted");
        return super.tokenURI(tokenId);
    }
}