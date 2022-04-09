// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// The NFT
contract Hero is IERC721, ERC721Enumerable {
    string private baseURI;

    constructor(string memory _baseUri) ERC721("Hero of Oasis", "HERO") {
        baseURI = _baseUri;
    }

    uint256 private nonce;

    function mint(address to) internal returns (uint256 id) {
        id = nonce++;
        _safeMint(to, id);
    }

    function burn(uint256 tokenId) internal returns (bool) {
        _burn(tokenId);
        return true;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }
}
