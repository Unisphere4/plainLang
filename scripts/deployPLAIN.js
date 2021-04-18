// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Deploy PLAINToken contract
  const Plain = await hre.ethers.getContractFactory("PLAINToken");
  const plain = await Plain.deploy();

  await plain.deployed();

  console.log("PLAINToken deployed to:", plain.address);

  // Deploy DEX
  //const Dex = await hre.ethers.getContractFactory("DEX");
  //const dex = await Dex.deploy(5);

  //await dex.deployed();

  //console.log("DEX deployed to:", dex.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
