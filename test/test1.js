const { waffle, hardhatArguments } = require("hardhat");
var chai = require('chai'); // for BigNumber. May be able to use ethers.BigNumber. 
const { expect } = require("chai");
const provider = waffle.provider;
var utils = require('ethers').utils;
const { BigNumber } = require("@ethersproject/bignumber");
const { checkResultErrors } = require("@ethersproject/abi");
chai.use(require('chai-bignumber')(BigNumber));

describe("PlainLang", () => {
    let Plain;
    let plain;
    let Dex;
    let dex;
    let Lang;
    let lang;
    let Price;
    let price;

    beforeEach(async () => {
        [owner, addr1, addr2, addr3, addr4, addr5, addr6,...addrs] = await ethers.getSigners();
        
        Plain = await hre.ethers.getContractFactory("PLAINToken");
        plain = await Plain.deploy();
        await plain.deployed();
        console.log("PLAIN token deployed at: ", plain.address);

        Dex = await hre.ethers.getContractFactory("DEX"); 
        dex = await Dex.deploy(plain.address, 2700);
        await dex.deployed();
        console.log("DEX deployed at: ", dex.address);

        Price = await hre.ethers.getContractFactory("PriceConsumerV3");
        price = await Price.deploy();
        await price.deployed();
        console.log("Price Consumer deployed at: ", price.address);

        Lang = await hre.ethers.getContractFactory("PlainLang");
        lang = await Lang.deploy(plain.address, price.address);
        await lang.deployed();
        console.log("PlainLang deployed at: ", lang.address);
    });

    it('Should result in addr2 owning 2700 PLAIN tokens: ', async () => {
        var val ="10000000000000000000";        // 10 Eth
        var val2="10000000000000000000";        // 10 Eth
        var val3="10000000000000000000";        // 10 Eth
        
        totalSupply = await plain.balanceOf(owner.address);
        await plain.transfer(dex.address, totalSupply);
        console.log("Transfer done");
        
        expect(await plain.balanceOf(owner.address)).to.equal(0);
        await dex.connect(addr2).buy({value: val});
        console.log("Buy 1 done");
        /*await dex.connect(addr3).buy({value: val2});
        console.log("Buy 2 done");
        await dex.connect(addr4).buy({value: val3});
        console.log("Buy 3 done");*/

        expect (await plain.balanceOf(addr2.address)).to.equal(BigNumber.from('27000000000000000000000'));
        console.log ("Balance of PLAIN held by addr3", await plain.balanceOf(addr3.address));
        console.log ("Balance of PLAIN held by addr4", await plain.balanceOf(addr4.address));

        // 2 Plain
        await plain.approve(lang.address, BigNumber.from('2000000000000000000'));
        //agreement_num = BigNumber.from(
        
        let myWallet = "0xC987f972320902aF8EE3E39e61b99fb5F3c96780";
        let genesis = "0x0000000000000000000000000000000000000000";
        let LINK = utils.getAddress('0x01BE23585060835E02B77ef475b0Cc51aA1e0709');
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [myWallet]});
        //                                           vvvvvvvvvvvvv Rinkeby LINK Contract vvvvvv
        const signer = await ethers.provider.getSigner(myWallet);
        
        await dex.connect(signer).buy({value: BigNumber.from('1000000000000000000')});
        console.log ("Balance of PLAIN held by the wallet address =", await plain.balanceOf(utils.getAddress(myWallet)));
        await plain.connect(signer).approve(lang.address, BigNumber.from('1000000000000000000'));
        console.log ("Amount of PLAIN approved = ", await plain.allowance(utils.getAddress(myWallet),lang.address));
        
        // Now call approve function of LINK
        let abi = ["function approve(address _spender, uint256 _value) public returns (bool success)"];
        let provider = ethers.getDefaultProvider('rinkeby');
        let contract = new ethers.Contract(LINK, abi, provider);
        console.log("LINK approve function returns: ", await contract.connect(signer).approve(lang.address, 20));
        
        await lang.connect(signer).createAgreement(LINK, 20, 5, 30, utils.getAddress(genesis));
        
        await network.provider.send("evm_increaseTime", [2678400]);
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [myWallet]});
    });
});