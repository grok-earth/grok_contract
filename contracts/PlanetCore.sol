// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Utils.sol";

contract PlanetCore is
    Base,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    IPlanetCore
{
    bytes32 private constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

    constructor() ERC721("Grok Planets", "PLANET") {}

    function setController(address controller)
        external
        onlyOwner
        isContract(controller)
    {
        grantRole(CONTROL_ROLE, controller);
    }

    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setTokenURI(uint256 tokenId, string memory tokenUri)
        external
        onlyRole(CONTROL_ROLE)
    {
        _setTokenURI(tokenId, tokenUri);
    }

    function mintOnce(address to, uint256 tokenId)
        public
        onlyRole(CONTROL_ROLE)
    {
        _mint(to, tokenId);
    }

    function burnPlanet(uint256 tokenId) public onlyRole(CONTROL_ROLE) {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
