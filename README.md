# ERC-1155 token mint with a EIP-2535 Diamonds proxy implementation using Hardhat and Solidity 0.8.*

This project is based on the implementation written by [Nick Mudge](https://github.com/mudgen/diamond-1-hardhat)

## Installation

1. Clone this repo:
```console
git clone https://github.com/luisvid/diamond-erc1155-mint.git
```

2. Install NPM packages:
```console
cd diamond-erc1155-mint
npm install
```

## Run tests:
```console
npx hardhat test
```

## Deployment

To complete the deployment of all the Diamond contracts on Sepolia testnet, first rename .env.example to .env, enter your private key and the required API keys, and then run the command:

```console
npx hardhat run scripts/deployDiamondWithERC1155.js --network sepolia
```

After all the required contracts have been deployed, you can use the [louper.dev](https://louper.dev/) tool to inspect and interact with the Diamond's contracts.

For example:

https://louper.dev/diamond/0xbC547CbA1949bb541dC7bc064789E536de17C12E?network=sepolia

## Facet Information


The `contracts/Diamond.sol` file shows an example of implementing a diamond.

The `contracts/facets/DiamondCutFacet.sol` file shows how to implement the `diamondCut` external function.

The `contracts/facets/DiamondLoupeFacet.sol` file shows how to implement the four standard loupe functions.

The `contracts/facets/ERC1155MintFacet.sol` file shows the ERC-1155 implementation.

The `contracts/libraries/LibDiamond.sol` file shows how to implement Diamond Storage and a `diamondCut` internal function.

The `scripts/deploy-test.js` file deploys all the facets, except for the ERC-1155 implementation, to be used in the tests.

