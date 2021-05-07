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

    it('Should result in addr2 owning 100 LINK tokens: ', async () => {
        let myWallet = "0xC987f972320902aF8EE3E39e61b99fb5F3c96780";
        let genesis = "0x0000000000000000000000000000000000000000";
        let LINK = utils.getAddress('0x01BE23585060835E02B77ef475b0Cc51aA1e0709');
        var val ="10000000000000000000";        // 10 Eth

        totalSupply = await plain.balanceOf(owner.address);
        await plain.transfer(dex.address, totalSupply);
        console.log("Transfer from owner to DEX done");

        await dex.connect(addr2).buy({value: val}); // Buy 10 ETH worth of PLAIN
        expect (await plain.balanceOf(addr2.address)).to.equal(BigNumber.from('27000000000000000000000'));
        console.log ("Balance of PLAIN held by addr2", await plain.balanceOf(addr2.address));

        /***********START IMPERSONATING WALLET**************/
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [myWallet]});
        const signer = await ethers.provider.getSigner(myWallet);  
        let abi = ["function approve(address _spender, uint256 _value) public returns (bool success)",
                   "function balanceOf(address account) public view returns (uint256)",
                   "function transfer(address recipient, uint256 amount) public returns (bool)"
        ];
        
        // let provider = ethers.getDefaultProvider('rinkeby');
        contract = await ethers.getContractAt(abi, LINK, signer);
        
        await dex.connect(signer).buy({value: BigNumber.from('1000000000000000000')}); // Sending 1 ETH => 2700 PLAIN
        console.log ("Balance of PLAIN held by the wallet address =", await plain.balanceOf(utils.getAddress(myWallet)));

        // Create agreement, staking 20,000,000 wei LINK
        await plain.connect(signer).approve(lang.address, BigNumber.from('5000000000000000000')); // Approve 5 PLAIN
        await contract.connect(signer).approve(lang.address, 100000000);
        let tx = await lang.connect(signer).createAgreement(LINK, BigNumber.from('20000000'), 5, 30, utils.getAddress(genesis));
        let receipt = await tx.wait();
        console.log(receipt.events?.filter((x) => {return x.event == "AgreementCreated"}));
        console.log ("Balance of LINK held by wallet", await contract.balanceOf(utils.getAddress(myWallet)));
        //******STOP IMPERSONATING WALLET********/
        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [myWallet]});
    
        // addr2 accepts signer's agreement
        await plain.connect(addr2).approve(lang.address, 1000);
        await lang.connect(addr2).acceptPremium(0);
        
        // Move forward in time past end of agreement
        await network.provider.send("evm_increaseTime", [2678400]);
        // addr2 closes agreement
        await lang.connect(addr2).closeAgreement(0);
        
        console.log ("Balance of LINK held by wallet", await contract.balanceOf(utils.getAddress(myWallet)));
        console.log ("Balance of LINK held by addr2", await contract.balanceOf(addr2.address));

        //*******ADD BAT********/
        //const BAT_RINK = '0xbf7a7169562078c96f0ec1a8afd6ae50f12e5a99'; //Tranfer is giving error on return
        //const BAT_ORACLE = '0x031dB56e01f82f20803059331DC6bEe9b17F7fC9';
        const DAI_RINK = '0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea';
        const DAI_ORACLE = '0x5e601CF5EF284Bcd12decBDa189479413284E1d2';
        const ZRX_RINK = '0xddea378a6ddc8afec82c36e9b0078826bf9e68b6';
        const ZRX_ORACLE = '0xF7Bbe4D7d13d600127B6Aa132f1dCea301e9c8Fc';

        await lang.addToken(DAI_RINK);
        await lang.addToken(ZRX_RINK);
        await price.addOracle(DAI_RINK, DAI_ORACLE);
        await price.addOracle(ZRX_RINK, ZRX_ORACLE);

        /***********START IMPERSONATING WALLET**************/
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [myWallet]});
        
        contract2 = await ethers.getContractAt(abi, DAI_RINK, signer);
        // Create agreement, staking 20,000,000 wei DAI
        await contract2.connect(signer).approve(lang.address, BigNumber.from('1000000000'));
        console.log ("Balance of DAI held by wallet before creating agreement", await contract2.balanceOf(utils.getAddress(myWallet)));
        await lang.connect(signer).createAgreement(DAI_RINK, BigNumber.from('20000'), 5, 30, utils.getAddress(genesis));
        
        contract3 = await ethers.getContractAt(abi, ZRX_RINK, signer);
        // Create agreement, staking 20,0000 wei ZRX
        await contract3.connect(signer).approve(lang.address, BigNumber.from('1000000000'));
        console.log ("Balance of ZRX held by wallet before creating agreement", await contract3.balanceOf(utils.getAddress(myWallet)));
        await lang.connect(signer).createAgreement(ZRX_RINK, BigNumber.from('20000'), 5, 30, utils.getAddress(genesis));

        await hre.network.provider.request({method: "hardhat_stopImpersonatingAccount",params: [myWallet]});
    });
});