// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./Utils.sol";

/**
 * Grok Core Contract
 */
contract GrokHonorsCore is Base, ERC20, ERC20Burnable {
    using Counters for Counters.Counter;

    address private _signServerAddress =
        0xDA3715DAAD1C0Efa35038A3634dDac025E19B054;

    mapping(address => Counters.Counter) private nonceMap;

    event WithdrawHonors(
        address indexed to,
        uint256 withDrawType,
        uint256 amount,
        uint256 nonce,
        bytes sign
    );

    constructor() ERC20("Grok Honors", "HONORS") {}

    function setSignServerAddress(address account)
        external
        onlyOwner
        isExternal(account)
    {
        _signServerAddress = account;
    }

    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function withDraw(
        uint256 withDrawType,
        uint256 amount,
        uint256 timestamp,
        bytes memory sign
    ) external {
        if (amount == 0) {
            revert("Mint grok failed, reason: invalid mint amount");
        }

        uint256 nonce = nonceMap[msg.sender].current();

        bytes memory message = abi.encodePacked(
            Utils.addressToUint256(msg.sender),
            amount,
            nonce,
            withDrawType,
            timestamp
        );

        if (!Utils.validSign(_signServerAddress, message, sign)) {
            revert("invalid signature");
        }

        _mint(address(msg.sender), amount * 10**decimals());
        nonceMap[msg.sender].increment();
        emit WithdrawHonors(msg.sender, withDrawType, amount, nonce, sign);
    }

    function ownerMint(address to, uint256 amount)
        external
        onlyOwner
        isExternal(to)
    {
        if (amount == 0) {
            revert("Mint grok failed, reason: invalid mint amount");
        }

        _mint(address(to), amount * 10**decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (!(from == address(0) || to == address(0))) {
            revert("paused");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
