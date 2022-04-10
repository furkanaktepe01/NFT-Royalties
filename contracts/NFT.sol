// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract NFT is ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 public cost =  1 ether;
    uint256 public maxSupply = 20;

    string baseURI;
    string public baseExtension = ".json";

    address public artist;
    uint256 public royaltyFee;

    event Sale(address from, address to, uint256 value);

    constructor(string memory _name, string memory _symbol, string memory _initBaseURI, uint256 _royaltyFee, address _artist) 
    ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        royaltyFee = _royaltyFee;
        artist = _artist;
    }

    function mint() public payable {  

        uint256 supply = totalSupply();
        
        require(supply < maxSupply);

        if (msg.sender != owner()) {
            
            require(msg.value >= cost);

            uint256 royalty = (msg.value * royaltyFee) / 100;
            
            _payRoyalty(royalty);

            (bool success_2, ) = payable(owner()).call{
                value: (msg.value - royalty)
            }("");

            require(success_2);
        }

        _safeMint(msg.sender, supply + 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
            ? string(
                abi.encodePacked(
                    currentBaseURI,
                    tokenId.toString(),
                    baseExtension
                )
              )
            : "";
    }

    function transferFrom (address from, address to, uint256 tokenId) public payable override {

        require (
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: Transfer caller is neither the owner nor approved."
        );

        if (msg.value > 0) {

            uint256 royalty = (msg.value * royaltyFee) / 100;
            
            _payRoyalty(royalty);

            (bool success_2, ) = payable(from).call{
                value: (msg.value - royalty)
            }("");

            require(success_2);

            emit Sale(from, to, msg.value);
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {

        if (msg.value > 0) {

            uint256 royalty = (msg.value * royaltyFee) / 100;
            
            _payRoyalty(royalty);

            (bool success_2, ) = payable(from).call{
                value: (msg.value - royalty)
            }("");

            require(success_2);

            emit Sale(from, to, msg.value);
        }

        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {

        require (
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: Transfer caller is not the owner or approved."
        );

        if (msg.value > 0) {

            uint royalty = (msg.value * royaltyFee) / 100;
            
            _payRoyalty(royalty);

            (bool success_2, ) = payable(from).call{
                value: (msg.value - royalty)
            }("");

            require(success_2);

            emit Sale(from, to, msg.value);
        }

        _safeTransfer(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _payRoyalty(uint256 _royalty) internal {

        (bool success_1, ) = payable(artist).call{ value: _royalty }("");
        
        require(success_1);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRoyaltyFee(uint256 _royaltyFee) public onlyOwner {
        royaltyFee = _royaltyFee;
    }

}
