const hre = require("hardhat");

async function main() {
  const RentMyNFT = await hre.ethers.getContractFactory("RentMyNFT");
  const rentMyNFT = await RentMyNFT.deploy();

  await rentMyNFT.deployed();
  console.log("RentMyNFT contract deployed to:", rentMyNFT.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
