const PurchaseAndSale = artifacts.require('./PurchaseAndSale.sol');
const LandRegistry = artifacts.require('./LandRegistry.sol');
const Property = artifacts.require('./Property.sol');
const EuroTokenBanking = artifacts.require('./EuroTokenBanking.sol');
const EuroToken = artifacts.require('./EuroToken.sol');
const PublicFinance = artifacts.require('./PublicFinance.sol');

contract('PurchaseContract', function(accounts) {
    let seller = accounts[0];
    let buyer = accounts[1];
    let notary = accounts[2];
    let registrar = accounts[3];
    let manager = accounts[4];
    let fakeDocument = accounts[5];
    
    let bank;
    let euroToken;

    let landRegistry;
    let property;
    let purchaseContract;
    let publicFinance;
    
    let lRInfo = {
        name: 'Hospitalet de Llobregat, L\' Nº 02',
        addressInfo: 'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
        province: 'Barcelona',
        telephone: '(93)475 26 85',
        fax: '(93)475 26 86',
        email: 'hospitalet2registrodelapropiedad.org'
    }

    before('setup land registry and property', async function() {
       
        bank = await EuroTokenBanking.new({from: manager});
        euroToken = await EuroToken.at(await bank.euroToken.call({from: manager}));
        await bank.cashIn(seller, 2000000000, {from: manager});
        await bank.cashIn(buyer,  2000000000, {from: manager});
        
        publicFinance = await PublicFinance.new({from: manager});
        await publicFinance.setEuroToken(euroToken.address, {from: manager});
        await publicFinance.addTax("ITP", 6, {from: manager});
        console.log('Prueba');
        landRegistry = await LandRegistry.new(
           lRInfo.name,
           lRInfo.addressInfo,
           lRInfo.province,
           lRInfo.telephone,
           lRInfo.fax,
           lRInfo.email
        , {from: manager});
        await landRegistry.setPublicFinance(publicFinance.address, {from: manager});
        await landRegistry.setRegistrar(registrar, {from: manager});

        property = await Property.new(1234, 1234, 'Calle Joan Maragall', seller, landRegistry.address, {from: registrar});
        //console.log('Property Created: ', property.address);
        await landRegistry.register(property.address, 34578, 'New Registration',  fakeDocument, {from: registrar});
        //console.log('Property registration state: ', await landRegistry.isRegistered.call(property.address, {from: registrar}));
        
        purchaseContract = await PurchaseAndSale.new(property.address, buyer, 1000000000, 10000000, {from: seller});
       // console.log(await purchaseContract.getBuyerDebts({from: manager}));
        await property.setPurchaseAndSaleContract(purchaseContract.address, {from: seller});
        
        // let sellerSummary = await purchaseContract.getSellerSummary({from: seller});
        // console.log('Seller Summary: ', sellerSummary);

    })

    it('allows buyer add a notary', async function() {
        await purchaseContract.addNotary(notary, {from: buyer});
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 1);
    })

    it('allows buyer pay the payment signal', async function() {
        let signal = (await purchaseContract.earnestMoney.call({from: buyer})).toNumber();
        await euroToken.approve(purchaseContract.address, signal/2, {from: buyer});
        await purchaseContract.payEarnestMoney({from: buyer});
        await euroToken.approve(purchaseContract.address, signal/2, {from: buyer});
        await purchaseContract.payEarnestMoney({from: buyer});
        let paid = (await purchaseContract.getSignerInfo(buyer, {from: buyer}))[2].toNumber();
        assert.equal(signal, paid);
    })

    it('allows seller pay the payment signal', async function() {
        let signal = (await purchaseContract.earnestMoney.call({from: seller})).toNumber();
        await euroToken.approve(purchaseContract.address, signal, {from: seller});
        await purchaseContract.payEarnestMoney({from: seller});
        let paid = (await purchaseContract.getSignerInfo(seller, {from: seller}))[2].toNumber();
        assert.equal(signal, paid);
    })

    it('changes its state to writting', async function() {
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 2);
    })

    it('allows notary set a contract hash', async function() {
        await purchaseContract.setPurchaseAndSaleContractHash('0xinvented', {from: notary});
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 3);
        
    })

    it('allows buyer and seller to validate the contract hash', async function() {
        await purchaseContract.validatePurchaseAndSaleContractHash('0xinvented', {from: buyer});
        await purchaseContract.validatePurchaseAndSaleContractHash('0xinvented', {from: seller});
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 4);
    })

    it('allows seller pay', async function() {
        let totalDebt = (await purchaseContract.getSignerInfo(seller, {from: seller}))[3].toNumber();
        console.log('Seller debts: ', totalDebt);
        if (totalDebt != 0) {
            await euroToken.approve(purchaseContract.address, totalDebt, {from: seller});
            await purchaseContract.payOutstandingPayments({from: seller});
        }
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 4);
    })

    it('allows buyer pay', async function() {
        let totalDebt = (await purchaseContract.getSignerInfo(buyer, {from: buyer}))[3].toNumber();
        console.log('Buyer debts: ', totalDebt);
        if (totalDebt != 0) {
            await euroToken.approve(purchaseContract.address, totalDebt, {from: buyer});
            await purchaseContract.payOutstandingPayments({from: buyer});
        }

        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 5);
    })

    it('allows buyer and seller sign', async function() {
        await purchaseContract.sign({from: seller});
        await purchaseContract.sign({from: buyer});
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 6);
    })

    it('allows registar calificate the contract', async function() {
        await purchaseContract.qualify(true, {from: registrar});
        let state = await purchaseContract.state.call({from: notary});
        assert.equal(state.toNumber(), 7);
    })

    it('is transfered', async function() {
        let newOwner = await property.owner.call({from: buyer});
        assert.equal(newOwner, buyer, 'The ownersip transfer was not successful');
        console.log((await euroToken.balanceOf(seller)).toNumber() / 10000);
        console.log((await euroToken.balanceOf(buyer)).toNumber() / 10000);
        console.log((await euroToken.balanceOf(publicFinance.address)).toNumber() / 10000);
    })

})