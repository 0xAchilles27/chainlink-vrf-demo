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

    
    uint64 subscriptionId;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 200000;
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
        uint256 rarity;
    }

    mapping(uint256 => string) requestToCharacterName;
    mapping(uint256 => address) requestToSender;

    Counters.Counter private _tokenIdCounter;


    mapping(uint256 => NFTStat) private characterRegistry;

    event ReceivedRandomness( uint256 reqId, uint256 n1, uint256 n2);
    event RequestedRandomness( uint256 reqId, address invoker, string name);

    constructor(uint64 _subscriptionId, address _vrfCoordinator) ERC721("OurNFTContract", "ONC") VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function safeMint(string calldata name) public returns(uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        requestToCharacterName[requestId] = name;
        requestToSender[requestId] = msg.sender;
        emit RequestedRandomness(requestId, msg.sender, name);
    }
    
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 w1 = randomWords[0];
        uint256 w2 = randomWords[1];
        uint8 p = uint8(w2 % 10);
        uint8 sp = uint8(w2 % 100 /10);
        uint16 c = uint16(w2 % 1000 / 100);


        address sender = requestToSender[requestId];
        string memory name = requestToCharacterName[requestId];
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(sender, tokenId);

        characterRegistry[tokenId] = NFTStat(
            true,
            sender,
            sender,
            name,
            p,
            sp,
            c,
            w1 % 10000
        );
        emit ReceivedRandomness(requestId, w1, w2);
            
    }
    // The following functions are overrides required by Solidity.

    function getCharacter(uint256 tokenId)
    public
    view
    returns (
        address,
        address,
        string memory,
        uint8,
        uint8,
        uint16
    ) {
        require(characterRegistry[tokenId].exists == true, "Character does not Exist.");
        return (
            characterRegistry[tokenId].currentOwner,
            characterRegistry[tokenId].originalOwner,
            characterRegistry[tokenId].characterName,
            characterRegistry[tokenId].power,
            characterRegistry[tokenId].specialPower,
            characterRegistry[tokenId].cooldown
        );
    }

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

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
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