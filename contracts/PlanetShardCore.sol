// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Utils.sol";

contract PlanetShardCore is ERC1155, AccessControl, Base {
    uint256 public constant N = 1;
    uint256 public constant R = 2;
    uint256 public constant SR = 3;

    bytes32 private constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

    constructor() ERC1155("") {}

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

    function setURI(string memory newuri) public onlyRole(CONTROL_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(CONTROL_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(CONTROL_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(CONTROL_ROLE) {
        _burnBatch(from, ids, amounts);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyRole(CONTROL_ROLE) {
        _burn(from, id, amount);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
