// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Utils.sol";

contract PlanetCtrl is Base {
    using Counters for Counters.Counter;
    using Address for address;
    using SafeERC20 for IERC20;

    Counters.Counter private _satelliteTokenIdCounter;
    Counters.Counter private _planetTokenIdCounter;
    mapping(address => Counters.Counter) private nonceMap;

    // [startPlanetTokenId, maxPlanetTokenid, startSatelliteTokenId]
    uint256[] private _tokenIdCfg = [1, 1000, 2001];

    address private _planetCoreAddress;
    address private _planetShardCoreAddress;
    address private _grokCoreAddress;

    uint256 public constant N = 1;
    uint256 public constant R = 2;
    uint256 public constant SR = 3;

    address payable private _receiveAddress;

    address private _signServerAddress =
        0xDA3715DAAD1C0Efa35038A3634dDac025E19B054;

    bool private _can_sell = true;

    // [0.1BNB, 0Grok]
    uint256[] private _payCfg = [0.1 ether, 0];

    string private _tokenURIPrefix = "https://storage.googleapis.com/grok-nft/";

    string private _tokenURISuffix = "/description.json";

    event BuyEvent(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256[] amounts
    );

    event SatelliteNonceEvent(
        address indexed addr,
        uint256 indexed nonce,
        uint256 ext
    );

    constructor(
        address planetCoreAddress,
        address planetShardCoreAddress,
        address payable receiveAddress,
        address grokCoreAddress
    ) isContract(planetCoreAddress) {
        _planetCoreAddress = planetCoreAddress;
        _planetShardCoreAddress = planetShardCoreAddress;
        _receiveAddress = receiveAddress;
        _grokCoreAddress = grokCoreAddress;
    }

    function moveOwner(address to) external onlyOwner isExternal(to) {
        transferOwnership(to);
    }

    function canSell() external view returns (bool) {
        return _can_sell;
    }

    function setSell(bool sell) external onlyOwner {
        _can_sell = sell;
    }

    function setPayAmount(uint256 mainCoin, uint256 grok) external onlyOwner {
        _payCfg = [mainCoin, grok];
    }

    function setTokenIdCfg(
        uint256 startPlanetTokenId,
        uint256 maxPlanetTokenid,
        uint256 startSatelliteTokenId
    ) external onlyOwner {
        _tokenIdCfg = [
            startPlanetTokenId,
            maxPlanetTokenid,
            startSatelliteTokenId
        ];
    }

    function getReceiveAddress() external view returns (address) {
        return _receiveAddress;
    }

    function setReceiveAddress(address payable receiveAddress)
        external
        onlyOwner
    {
        _receiveAddress = receiveAddress;
    }

    function setGrokAddress(address payable grokCoreAddress)
        external
        onlyOwner
    {
        _grokCoreAddress = grokCoreAddress;
    }

    function setSignServerAddress(address account)
        external
        onlyOwner
        isExternal(account)
    {
        _signServerAddress = account;
    }

    function isOwns(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return (IERC721(_planetCoreAddress).ownerOf(tokenId) == account);
    }

    function getPlanetTokenId() internal returns (uint256) {
        uint256 tokenId = _planetTokenIdCounter.current() + _tokenIdCfg[0];
        _planetTokenIdCounter.increment();
        return tokenId;
    }

    function getSatelliteTokenId() internal returns (uint256) {
        uint256 tokenId = _satelliteTokenIdCounter.current() + _tokenIdCfg[2];
        _satelliteTokenIdCounter.increment();
        return tokenId;
    }

    function getNonce(uint256 ext) internal returns (uint256) {
        uint256 nonce = nonceMap[msg.sender].current();
        nonceMap[msg.sender].increment();

        emit SatelliteNonceEvent(msg.sender, nonce, ext);
        return nonce;
    }

    function airdrop() external onlyOwner {
        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = _mintPlanet(_receiveAddress);
            require(tokenId <= (_tokenIdCfg[0] + 10));
        }
    }

    function _mintSatellite(address to) internal returns (uint256) {
        if (!_can_sell) {
            revert("can not sell");
        }
        uint256 tokenId = getSatelliteTokenId();
        IPlanetCore(_planetCoreAddress).mintOnce(to, tokenId);
        IPlanetCore(_planetCoreAddress).setTokenURI(
            tokenId,
            createTokenURI(tokenId)
        );

        emit BuyEvent(address(0), address(msg.sender), tokenId, _payCfg);
        return tokenId;
    }

    function _mintPlanet(address to) internal returns (uint256) {
        require(_can_sell, "can not sell");

        uint256 tokenId = getPlanetTokenId();
        require(tokenId <= _tokenIdCfg[1], "mint limit");

        IPlanetCore(_planetCoreAddress).mintOnce(to, tokenId);
        IPlanetCore(_planetCoreAddress).setTokenURI(
            tokenId,
            createTokenURI(tokenId)
        );

        emit BuyEvent(address(0), address(msg.sender), tokenId, _payCfg);
        return tokenId;
    }

    function shardMint(
        uint256 timestamp,
        uint256 NAmount,
        uint256 RAmount,
        uint256 SRAmount,
        bytes memory sign
    ) public payable isExternal(msg.sender) {
        uint256 nonce = getNonce(1);
        bytes memory message = abi.encodePacked(
            Utils.addressToUint256(msg.sender),
            nonce,
            timestamp,
            NAmount,
            RAmount,
            SRAmount
        );
        require(
            Utils.validSign(_signServerAddress, message, sign),
            "invalid signature"
        );

        IPlanetShardCore(_planetShardCoreAddress).mint(
            msg.sender,
            N,
            NAmount,
            ""
        );
        IPlanetShardCore(_planetShardCoreAddress).mint(
            msg.sender,
            R,
            RAmount,
            ""
        );
        IPlanetShardCore(_planetShardCoreAddress).mint(
            msg.sender,
            SR,
            SRAmount,
            ""
        );
    }

    function unionSatelliteBatch(
        uint256 timestamp,
        uint256 count,
        uint256 NAmount,
        uint256 RAmount,
        uint256 SRAmount,
        bytes memory sign
    ) public payable isExternal(msg.sender) {
        uint256 mainCoin = _payCfg[0] * count;
        // uint256 payGrok = _payCfg[1] * count;
        require(msg.value == mainCoin, "mainCoin, reason: not enough balance");
        // require(
        //     IERC20(_grokCoreAddress).balanceOf(address(msg.sender)) >= payGrok,
        //     "grok, reason: not enough balance"
        // );

        bytes memory message = abi.encodePacked(
            Utils.addressToUint256(msg.sender),
            count,
            timestamp,
            NAmount,
            RAmount,
            SRAmount
        );
        require(
            Utils.validSign(_signServerAddress, message, sign),
            "invalid signature"
        );

        IPlanetShardCore(_planetShardCoreAddress).burn(msg.sender, N, NAmount);
        IPlanetShardCore(_planetShardCoreAddress).burn(msg.sender, R, RAmount);
        IPlanetShardCore(_planetShardCoreAddress).burn(
            msg.sender,
            SR,
            SRAmount
        );

        _receiveAddress.transfer(mainCoin);

        // IERC20(_grokCoreAddress).safeTransferFrom(
        //     address(msg.sender),
        //     address(_receiveAddress),
        //     payGrok
        // );

        for (uint256 i = 0; i < count; i++) {
            _mintSatellite(msg.sender);
        }
    }

    // function unionSatellite(uint256 timestamp, bytes memory sign)
    //     public
    //     payable
    //     isExternal(msg.sender)
    // {
    //     require(msg.value == _payCfg[0], "mainCoin, reason: not enough balance");
    //     // require(
    //     //     IERC20(_grokCoreAddress).balanceOf(address(msg.sender)) >=
    //     //         _payCfg[1],
    //     //     "grok, reason: not enough balance"
    //     // );

    //     uint256 nonce = getNonce(1);
    //     bytes memory message = abi.encodePacked(
    //         Utils.addressToUint256(msg.sender),
    //         nonce,
    //         timestamp
    //     );
    //     require(
    //         Utils.validSign(_signServerAddress, message, sign),
    //         "invalid signature"
    //     );

    //     _receiveAddress.transfer(_payCfg[0]);

    //     // IERC20(_grokCoreAddress).safeTransferFrom(
    //     //     address(msg.sender),
    //     //     address(_receiveAddress),
    //     //     _payCfg[1]
    //     // );

    //     _mintSatellite(msg.sender);
    // }

    function unionPlanet(
        uint256 timestamp,
        uint32[] memory satelliteTokens,
        bytes memory sign
    ) public payable isExternal(msg.sender) {
        require(msg.value == _payCfg[0], "mainCoin, reason: not enough balance");
        // require(
        //     IERC20(_grokCoreAddress).balanceOf(address(msg.sender)) >=
        //         _payCfg[1],
        //     "grok, reason: not enough balance"
        // );

        bytes memory message = abi.encodePacked(
            Utils.addressToUint256(msg.sender),
            timestamp,
            satelliteTokens
        );
        require(
            Utils.validSign(_signServerAddress, message, sign),
            "invalid signature"
        );

        _receiveAddress.transfer(_payCfg[0]);

        // IERC20(_grokCoreAddress).safeTransferFrom(
        //     address(msg.sender),
        //     address(_receiveAddress),
        //     _payCfg[1]
        // );

        for (uint256 i = 0; i < satelliteTokens.length; i++) {
            require(isOwns(msg.sender, satelliteTokens[i]), "owner error");
            IPlanetCore(_planetCoreAddress).burnPlanet(satelliteTokens[i]);
        }

        _mintPlanet(msg.sender);
    }

    function burnSatellite(
        uint256 timestamp,
        uint32[] memory tokens,
        uint256 grokAmount,
        bytes memory sign
    ) public isExternal(msg.sender) {
        require(_can_sell, "can not sell");

        bytes memory message = abi.encodePacked(
            Utils.addressToUint256(msg.sender),
            grokAmount,
            timestamp,
            tokens
        );
        require(
            Utils.validSign(_signServerAddress, message, sign),
            "invalid signature"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            require(isOwns(msg.sender, tokens[i]), "owner error");
            IPlanetCore(_planetCoreAddress).burnPlanet(tokens[i]);
        }

        uint256 amountWei = grokAmount * 10**18;
        if (currentBalance() < amountWei) {
            revert("Transfer failed, reason: not enough amount");
        }

        IERC20(_grokCoreAddress).transfer(address(msg.sender), amountWei);
    }

    function currentBalance() public view returns (uint256) {
        return IERC20(_grokCoreAddress).balanceOf(address(this));
    }

    function setTokenURIPrefix(string memory tokenURIPrefix)
        external
        onlyOwner
    {
        _tokenURIPrefix = tokenURIPrefix;
    }

    function setTokenURISuffix(string memory tokenURISuffix)
        external
        onlyOwner
    {
        _tokenURISuffix = tokenURISuffix;
    }

    function createTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory _tokenId = toString(tokenId);
        string memory uri = concatTokenURI(_tokenId);

        return uri;
    }

    function concatTokenURI(string memory tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(abi.encodePacked(_tokenURIPrefix, tokenId, _tokenURISuffix));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
