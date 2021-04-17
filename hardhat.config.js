require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');
require("ethereum-waffle")

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 **/
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0"
      },
      {
        version: "0.7.3",
        settings: { }
      }]
  },
  gas: "auto",
  abiExporter: {
    path: './data/abi',
    clear: true,
    flat: false,
    //only: [':ERC20$'],
    spacing: 2
  },
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/R5ThfUtxW3rZT-rl2sJKVmppPyAiP918`,
      accounts: [`0x6c14a598cb42ae418c83c600fae61d789bfda6da481ebfb4edbbbc5466ad07f0`]
    }
  }  
};