// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // For counting the tokenId increment:
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 100;
    uint256 public maxMintAmount = 20;
    uint256 public maxBreedingCount = 5;
    // Setting limit per wallet:
    uint256 public maxNftPerAddress = 2;
    bool public paused = false;
    bool public revealed = false;
    bool public authoriseBreed = false;

    // Boolean to take into consideration of WL ornot:
    bool public onlyWhitelisted = true;

    //   mapping(address => bool) public whitelisted;
    address[] public whitelistedAddresses;

    // Breeding count:
    mapping(uint256 => uint256) public breedingCount;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused);

        uint256 supply = totalSupply();

        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            // if(whitelisted[msg.sender] != true) {

            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");

                // Check for how many nfts in the wallet:
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require(
                    ownerTokenCount < maxNftPerAddress,
                    "max mint exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount);
            // }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to breed from 2 'genesis' tokens:
    function breed(uint256 _tokenId1, uint256 _tokenId2) external {
        require(authoriseBreed == true, "Breeding not enabled yet!");
        require(
            ownerOf(_tokenId1 + 1) == msg.sender &&
                ownerOf(_tokenId2 + 1) == msg.sender,
            "Dont have 2 NFTs to breed."
        );

        require(_tokenId1 <= 20 && _tokenId2 <= 20, "Not genesis tokens");

        // Require both NFT to have a breeding count of max 5:
        require(
            breedingCount[_tokenId1] <= 5 && breedingCount[_tokenId2] <= 5,
            "Breed limit maxed out!"
        );

        // If all requirements are met, update breeding Count:
        breedingCount[_tokenId1]++;
        breedingCount[_tokenId2]++;

        uint256 supply = totalSupply();

        // Breed and mint a new NFT:
        _safeMint(msg.sender, supply + 1);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
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

        if (revealed == false) {
            return notRevealedUri;
        }

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

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Setting limit for each wallet
    function setNftPerAddress(uint256 _newLimit) public onlyOwner {
        maxNftPerAddress = _newLimit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setAuthoriseBreed(bool _state) public onlyOwner {
        authoriseBreed = _state;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // Toggle for whitelist only
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        // whitelisted[_user] = true;

        // Clear exisiting ones:
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    //   function removeWhitelistUser(address _user) public onlyOwner {
    //     whitelisted[_user] = false;
    //   }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

/*
["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]



*/
