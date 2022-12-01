// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";

contract NFTs is Ownable, ERC721Enumerable, ILayerZeroReceiver {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 1 ether;
    uint256 public maxSupply = 8;
    uint256 public supply = 0;
    bool public paused = false;
    ILayerZeroEndpoint public endpoint;
    uint256 public gas = 350000;

    event Recieve(
        uint16 _srcChainId,
        address _from,
        uint256 tokenId
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _endpoint
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint() public payable {
        require(!paused);
        require(supply <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost);
        }

        _safeMint(msg.sender, supply + 1);
        supply += 1;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function solidityPack(address remote, address local) public pure returns (bytes memory) {
        return abi.encodePacked(remote, local);
    }

    function CrossChainTransfer(
        uint16 _dstChainId,
        bytes calldata _dstAddress,
        uint256 tokenId
    ) public payable {        
        require(msg.sender == ownerOf(tokenId), "Not the Owner");

        _burn(tokenId);
        supply -= 1;

        bytes memory payload = abi.encode(msg.sender);
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId, 
            address(this), 
            payload, 
            false, 
            adapterParams
        );

        require(msg.value >= messageFee, "Must send enough gas to cover Message Fee");
        endpoint.send{value : msg.value}(
            _dstChainId,
            _dstAddress,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId, 
        bytes memory _srcAddress, 
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        address from;

        assembly {
            from := mload(add(_srcAddress, 20))
        }

        (address _dstAddress) = abi.decode(
            _payload,
            (address)
        );

        require(supply <= maxSupply);

        _safeMint(_dstAddress, supply + 1);
        supply += 1;
        emit Recieve(_srcChainId, _dstAddress, supply);
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}