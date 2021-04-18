const { waffle } = require("hardhat");
var chai = require('chai'); // for BigNumber. May be able to use ethers.BigNumber. 
const { expect } = require("chai");
const provider = waffle.provider;
var utils = require('ethers').utils;
const { BigNumber } = require("@ethersproject/bignumber");
const { checkResultErrors } = require("@ethersproject/abi");
chai.use(require('chai-bignumber')(BigNumber));

describe("PLAINToken", () => {
    let Plain;
    let plain;

    beforeEach(async () => {
        Plain = await hre.ethers.getContractFactory("PLAINToken");
        [owner, addr1, addr2, addr3, addr4, addr5, addr6,...addrs] = await ethers.getSigners();
        
        plain = await Plain.deploy();
        await plain.deployed();

        Dex = await hre.ethers.getContractFactory("DEX"); 
        dex = await Dex.deploy(plain.address, 2700);
        await dex.deployed();
    });

    it('Should result in addr2 owning 2700 PLAIN tokens: ', async () => {
        var val="18518000000000000000000";
        var val2="43290000000000000000000";
        var val3="639142857142857142857";
        var remainder = "10";
        totalSupply = await plain.balanceOf(owner.address);
        totalSupply2 = totalSupply.sub(10);
        await plain.transfer(dex.address, totalSupply2);
        await plain.transfer(addr5.address, remainder);
        
        //expect(await plain.balanceOf(dex.address)).to.equal(await plain.totalSupply());
        expect(await plain.balanceOf(owner.address)).to.equal(0);
        await dex.connect(addr2).buy({value: val});
        await dex.connect(addr3).buy({value: val2});
        await dex.connect(addr4).buy({value: val3});
        /*await dex.connect(addr5).buy({value: val});
        await dex.connect(addr6).buy({value: val});*/

        await dex.transferFees(0);
        console.log("owner eth balance: ", await owner.getBalance());

        var ts = BigNumber.from(await plain.totalSupply());
        var bal = BigNumber.from(await plain.balanceOf(dex.address));
        result = ts.sub(bal);
        console.log("result = ", result);
        divided = result.div('32320000000000000000000');
        console.log("divided =", divided);

        console.log("addr2 PLAIN balance:", await plain.balanceOf(addr2.address));
        console.log("addr3 PLAIN balance:", await plain.balanceOf(addr3.address));
        console.log("addr4 PLAIN balance:", await plain.balanceOf(addr4.address));
        console.log("addr5 PLAIN balance:", await plain.balanceOf(addr5.address));
        //console.log("addr6 PLAIN balance:", await plain.balanceOf(addr6.address));
        console.log("exchange_rate = ", await dex.exchange_rate());
        console.log("balance of PLAIN held by DEX=", await plain.balanceOf(dex.address));
        console.log("total_supply = ", await plain.totalSupply());
        //console.log("owner owns: ", await plain.balanceOf(owner.address));
        //console.log("DEX owns: ", await plain.balanceOf(dex.address));
    });

    it('Should result in owner having the correct balance: ', async () => {
        expect(await plain.balanceOf(owner.address)).to.equal(await plain.totalSupply());
      });

    it('Should result in addr1 having 250 tokens, addr2 having 250 tokens, and addr3 having 125 tokens: ', async function() {
        await plain.transfer(addr1.address, 500);
        addr1Balance = await plain.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(500);
        await plain.connect(addr1).transfer(addr2.address, 250);
        addr2Balance = await plain.balanceOf(addr2.address);
        addr1Balance = await plain.balanceOf(addr1.address);
        //console.log("addr1Balance", addr1Balance);
        expect(addr2Balance).to.equal(250);
        expect(addr1Balance).to.equal(250);
        await plain.connect(addr2).transfer(addr3.address, 125);
        addr3Balance = await plain.balanceOf(addr3.address);
        expect(addr3Balance).to.equal(125);    

        // Test approve()
        expect(await plain.connect(addr3).approve(owner.address, 125)==true);
        const approval_amount = await plain.allowance(addr3.address, owner.address);
        expect(approval_amount).to.equal(125);
        
        await plain.transferFrom(addr3.address, addr2.address, 70);
        addr2Balance=await plain.balanceOf(addr2.address);
        expect(addr2Balance).to.equal(195);

        await plain.transferFrom(addr3.address, addr2.address, 55);
        addr3Balance=await plain.balanceOf(addr3.address);
        expect(addr3Balance).to.equal(0);

    });
    
    it ("Should return the total supply of the tokens once it is deployed: ", async function (){
        expect(await plain.totalSupply()).to.equal("100000000000000000000000000");
    });

    it ("Should return the name of the token:", async function () {
        expect(await plain.name()).to.equal("PLAINToken");
    });
});