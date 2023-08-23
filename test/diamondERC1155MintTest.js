/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy-test.js')

const { assert, expect } = require('chai')

describe('DiamondTest', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let erc1155MintFacet
  let tx
  let receipt
  let result
  const addresses = []

  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
  })

  it('should have three facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }
    assert.equal(addresses.length, 3)
  })

  it('should add ERC1155MintFacet functions', async () => {
    // Deploy ERC1155MintFacet
    const ERC1155MintFacet = await ethers.getContractFactory('ERC1155MintFacet')
    erc1155MintFacet = await ERC1155MintFacet.deploy()
    await erc1155MintFacet.deployed()
    console.log(`ERC1155MintFacet deployed: ${erc1155MintFacet.address}`)
    addresses.push(erc1155MintFacet.address)

    // Add ERC1155MintFacet functions
    const functionsToKeep = ['mint(uint256,uint256,string)', 'uri(uint256)']
    const selectors = getSelectors(erc1155MintFacet).get(functionsToKeep)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: erc1155MintFacet.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    // Check ERC1155MintFacet functions
    result = await diamondLoupeFacet.facetFunctionSelectors(erc1155MintFacet.address)
    assert.sameMembers(result, selectors)
  })

  it('should have Four facets -- call to facetAddresses function', async () => {
    const facets = await diamondLoupeFacet.facetAddresses()
    assert.equal(facets.length, 4)
  })

  it("Should reject URIs that don't end with .glb", async function () {
    await expect(erc1155MintFacet.mint(1, 100, "https://example.com/token.jpg"))
      .to.be.revertedWith("URI should end with .glb file extension.");
  });

  it("Should mint with a valid URI", async function () {
    await expect(erc1155MintFacet.mint(1, 100, "https://example.com/token.glb"))
      .to.emit(erc1155MintFacet, 'TransferSingle');
  });
  
  it("Should retrieve the correct URI after minting", async function () {
    expect(await erc1155MintFacet.uri(1)).to.equal("https://example.com/token.glb");
  });

  it("Shouldn't allow an address to mint more than once", async function () {
    await expect(erc1155MintFacet.mint(2, 50, "https://example.com/token2.glb"))
      .to.be.revertedWith("Address has already minted.");
  });

})
