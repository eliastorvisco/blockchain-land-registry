const EuroTokenBanking = artifacts.require('./EuroTokenBanking.sol');
const EuroToken = artifacts.require('./EuroToken.sol');

contract('EuroToken and EuroTokenBanking', function(accounts) {
    let manager = accounts[0];
    let elias = accounts[1];
    let marti = accounts[2];
    let euroTokenBanking;
    let euroToken;

    let decimals;

   

    // beforeEach('setup bank and euro token', async function() {
        
    // })

    it('setup', async function() {
        euroTokenBanking = await EuroTokenBanking.new({from: manager});
        //euroTokenBanking = await EuroTokenBanking.at("0xc8d03031a55eaf3b4d032891f07572565eded002");
        console.log("Bank: ", euroTokenBanking.address);
        euroToken = await EuroToken.at(await euroTokenBanking.euroToken.call());
        console.log("Token: ", euroToken.address);
        decimals = await euroToken.decimals.call();
    })

    it('can cash in money to an account', async function() {
        let money = 100;
        await euroTokenBanking.cashIn(elias, money*Math.pow(10, decimals), {from: manager});
        let eliasBalance = await euroToken.balanceOf(elias, {from: elias});
        assert.equal(100, eliasBalance.toNumber() / Math.pow(10, decimals));
    })

    it('can cash out money from an account', async function() {
        await euroTokenBanking.cashOut(150000, "Cuenta Inventada", {from: elias});
        let eliasBalance = await euroToken.balanceOf(elias, {from: elias});
        console.log(eliasBalance.toNumber());
        //assert.equal(85, eliasBalance.toNumber() / Math.pow(10, decimals));
    })

    it('can transfer money', async function() {
        let money = 25;
        await euroToken.transfer(marti, 250000, {from: elias});
        //await euroToken.approve(marti, 250000, {from: elias});
        //await euroToken.transferFrom(elias, marti, 250000, {from: marti});
        console.log(await euroToken.balanceOf(marti, {from: elias})/Math.pow(10, decimals));

    })
})