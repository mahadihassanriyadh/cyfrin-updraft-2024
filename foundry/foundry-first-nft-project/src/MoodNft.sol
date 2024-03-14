// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_sadSvgImgUri;
    string private s_happySvgImgUri;

    enum Mood {
        SAD,
        HAPPY
    }
    mapping(uint256 => Mood) private s_tokenIdToMood;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _sadSvgImgUri,
        string memory _happySvgImgUri
    ) ERC721(_name, _symbol) {
        s_tokenCounter = 0;
        _sadSvgImgUri = _sadSvgImgUri;
        _happySvgImgUri = _happySvgImgUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        string memory imageURI;
        if (s_tokenIdToMood[_tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImgUri;
        } else {
            imageURI = s_sadSvgImgUri;
        }

        // string.concat and abi.encodePacked are two ways to concatenate strings in Solidity.
        /*  
            // ⭐️ string.concat
                string memory tokenMetaData = string.concat(
                    '"name": "',
                    name(),
                    '", "description": "An NFT that represents the mood of the owner", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "',
                    imageURI,
                    '"}'
                );

            // ⭐️ abi.encodePacked
                bytes memory convertedMetaData = abi.encodePacked(
                    '"name": "',
                    name(),
                    '", "description": "An NFT that represents the mood of the owner", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "',
                    imageURI,
                    '"}'
                );
        */

        // we are using abi.encodePacked to concatenate the strings here, because we need the data in bytes. As openzeppelin's Base64.encode() function expects the data to be in bytes to convert it into base64.
        bytes memory tokenMetaData = abi.encodePacked(
            '"name": "',
            name(),
            '", "description": "An NFT that represents the mood of the owner", "attributes": [{"trait_type": "moodiness", "value": 100}], "image": "',
            imageURI,
            '"}'
        );

        // convert the metadata to base64
        string memory base64TokenMetaData = Base64.encode(tokenMetaData);

        // concatenate the baseURI and the base64TokenMetaData
        return string(abi.encodePacked(_baseURI(), base64TokenMetaData));
    }
}
