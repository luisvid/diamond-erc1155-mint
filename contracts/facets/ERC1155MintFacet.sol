// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Library for handling the shared storage structure for the ERC1155MintFacet.
library ERC1155MintFacetLib {
    // Define a unique storage position for our diamond storage.
    // This is done to avoid any potential storage layout conflicts with other facets.
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.erc1155mintfacet.storage");

    // Define the structure that represents our facet's state in storage.
    struct MintFacetState {
        mapping(address => bool) hasMinted; // Track if an address has minted a token.
        mapping(uint256 => string) tokenURIs; // Store unique URIs for each token ID.
    }

    // Function to access the MintFacetState in storage.
    // Utilizes inline assembly for optimized, direct Ethereum storage access.
    function diamondStorage() internal pure returns (MintFacetState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position // Set the storage slot for our MintFacetState structure.
        }
    }
}

contract ERC1155MintFacet is ERC1155 {
    using Strings for uint256;
    using ERC1155MintFacetLib for ERC1155MintFacetLib.MintFacetState;

    constructor() ERC1155("") {} // Base URI will be set later, if required

    /**
     * @notice Mints a new ERC1155 token
     * @param id - Token ID
     * @param amount - Amount of the token to be minted
     * @param tokenUri - Token URI, should end with .glb
     */
    function mint(uint256 id, uint256 amount, string calldata tokenUri) external {
        // Use the library to access storage
        require(!ERC1155MintFacetLib.diamondStorage().hasMinted[msg.sender], "Address has already minted.");

        // Ensure the tokenUri ends with .glb
        require(endsWith(tokenUri), "URI should end with .glb file extension.");

        // Update the minting status of the address
        ERC1155MintFacetLib.diamondStorage().hasMinted[msg.sender] = true;

        // Set the URI for the token ID
        _setTokenURI(id, tokenUri);

        // Mint the token to the sender's address
        _mint(msg.sender, id, amount, "");
    }

    /**
     * @notice Check if the given URI string ends with '.glb' extension
     * @param value The URI string to be checked
     * @return bool Returns true if the URI ends with '.glb', otherwise false
     */
    function endsWith(string memory value) public pure returns (bool) {
        // Working with bytes is generally more gas-efficient in Solidity than working with strings,
        // especially when you're doing operations that inspect or change individual characters.
        // This method will be cheaper than a substring and hash comparison,
        // as it avoids both creating a new dynamic array and the gas cost of hashing.
        bytes memory byteArray = bytes(value);
        if (byteArray.length < 4) {
            return false;
        }
        return
            byteArray[byteArray.length - 4] == "." &&
            byteArray[byteArray.length - 3] == "g" &&
            byteArray[byteArray.length - 2] == "l" &&
            byteArray[byteArray.length - 1] == "b";
    }

    /**
     * @notice Internal function to set the URI for a specific token ID
     * @param tokenId - ID of the token to set its URI
     * @param newuri - URI to be associated with token ID
     */
    function _setTokenURI(uint256 tokenId, string memory newuri) internal virtual {
        ERC1155MintFacetLib.diamondStorage().tokenURIs[tokenId] = newuri;
    }

    /**
     * @notice Returns the URI for a specific token ID
     * @param tokenId - ID of the token to query
     * @return string Returns the associated URI or reverts if not set
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = ERC1155MintFacetLib.diamondStorage().tokenURIs[tokenId];

        // Revert if there's no URI for this token ID
        require(bytes(_tokenURI).length > 0, "URI not set for this token ID");

        return _tokenURI;
    }
}
