// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const NFTs = await hre.ethers.getContractFactory("NFTs");
    const nfts = await NFTs.deploy(
      "OMNI-NFTs",
      "OMNI",
      "https://ipfs.io/ipfs/QmYxrWRUgBYssNCSKjuBiCf6kEDqrK98oivBwV6TrhqChb/",
      "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8"
      );

    await nfts.deployed();

    console.log(
      `NFTs Smart-Contract deployed to ${nfts.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
