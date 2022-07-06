// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IPlanetCore {
    function setTokenURI(uint256 tokenId, string memory tokenUri) external;

    function mintOnce(address to, uint256 tokenId) external;

    function burnPlanet(uint256 tokenId) external;
}

interface IPlanetShardCore {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}

interface IPlanetCtrl {
    function isOwns(address account, uint256 tokenId)
        external
        view
        returns (bool);
}

contract Base is Ownable, AccessControl, Pausable {
    event DebugLog(string info);

    modifier isContract(address account) {
        require(
            Address.isContract(account),
            "Caller is not a contract address"
        );
        _;
    }

    modifier isExternal(address account) {
        require(
            !Address.isContract(account),
            "Caller is not a external address"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    function debugLog(string memory info) internal {
        emit DebugLog(info);
    }
}

library Utils {
    function validSign(
        address from,
        bytes memory message,
        bytes memory sign
    ) internal pure returns (bool) {
        bytes32 _message = ECDSA.toEthSignedMessageHash(keccak256(message));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            _message,
            sign
        );

        if (error != ECDSA.RecoverError.NoError) {
            return false;
        }

        if (from != recovered) {
            return false;
        }

        return true;
    }

    function addressToUint160(address account) internal pure returns (uint160) {
        return uint160(account);
    }

    function uint160ToAddress(uint160 value) internal pure returns (address) {
        return address(value);
    }

    function addressToUint256(address account) internal pure returns (uint256) {
        return uint256(uint160(account));
    }

    function uint256ToString(uint256 value)
        internal
        pure
        returns (string memory)
    {
        return bytesToString(abi.encodePacked(value));
    }

    function addressToString(address account)
        internal
        pure
        returns (string memory)
    {
        return bytesToString(abi.encodePacked(account));
    }

    function bytesToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function seedRandom(string memory seed) internal view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            seed,
                            block.timestamp,
                            block.difficulty
                        )
                    )
                ) % 100
            );
    }
}
