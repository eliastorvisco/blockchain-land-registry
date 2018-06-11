const PurchaseContract = artifacts.require('./PurchaseContract.sol');
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
        
        purchaseContract = await PurchaseContract.new(property.address, buyer, 1000000000, 10000000, {from: seller});
       // console.log(await purchaseContract.getBuyerDebts({from: manager}));
        await property.setPurchaseContract(purchaseContract.address, {from: seller});
        
        // let sellerSummary = await purchaseContract.getSellerSummary({from: seller});
        // console.log('Seller Summary: ', sellerSummary);

    })

    it('allows buyer add a notary', async function() {
        await purchaseContract.addNotary(notary, {from: buyer});
        let state = await purchaseContract.phase.call({from: notary});
        assert.equal(state.toNumber(), 1);
    })

    it('allows buyer pay the payment signal', async function() {
        let signal = (await purchaseContract.paymentSignal.call({from: buyer})).toNumber();
        await euroToken.approve(purchaseContract.address, signal, {from: buyer});
        let paid = (await purchaseContract.getBuyerSignalPayment({from: buyer}))[1].toNumber();
        assert.equal(signal, paid);
    })

    it('allows seller pay the payment signal', async function() {
        let signal = (await purchaseContract.paymentSignal.call({from: seller})).toNumber();
        await euroToken.approve(purchaseContract.address, signal, {from: seller});
        let paid = (await purchaseContract.getSellerSignalPayment({from: seller}))[1].toNumber();
        assert.equal(signal, paid);
    })

    it('changes its phase to writting', async function() {
        await purchaseContract.checkSignalPayment({from: buyer});
        let state = await purchaseContract.phase.call({from: notary});
        assert.equal(state.toNumber(), 2);
    })

    it('allows notary set a contract hash', async function() {
        await purchaseContract.cancel({from: notary});
        // await purchaseContract.setContractHash('0xinvented', {from: notary});
        // let state = await purchaseContract.phase.call({from: notary});
        // assert.equal(state.toNumber(), 3);
        
    })

    // it('allows buyer and seller to validate the contract hash', async function() {
    //     await purchaseContract.validateContractDocument('0xinvented', {from: buyer});
    //     await purchaseContract.validateContractDocument('0xinvented', {from: seller});
    //     let state = await purchaseContract.phase.call({from: notary});
    //     assert.equal(state.toNumber(), 4);
    // })

    // it('allows seller pay', async function() {
    //     let totalDebt = (await purchaseContract.getSellerDebts({from: seller}))[0].toNumber();
    //     let signal = (await purchaseContract.paymentSignal.call({from: seller})).toNumber();
    //     await euroToken.approve(purchaseContract.address, signal + totalDebt, {from: seller});
    //     await purchaseContract.updatePayment({from: seller});
    //     let state = await purchaseContract.phase.call({from: notary});
    //     assert.equal(state.toNumber(), 4);
    // })

    // it('allows buyer pay', async function() {
    //     // let dest = await purchaseContract.getBuyerDebtDestinataries({from: buyer});
    //     // let debtsPromise =  dest.map(async destinatary => {
    //     //     let res = await purchaseContract.getBuyerDebtWith(destinatary, {from: buyer});
    //     //     return res.toNumber();
    //     // });

    //     // let debts = await Promise.all(debtsPromise);

    //     let totalDebt = (await purchaseContract.getBuyerDebts({from: buyer}))[0].toNumber();
    //     let signal = (await purchaseContract.paymentSignal.call({from: seller})).toNumber();
    //     await euroToken.approve(purchaseContract.address, signal + totalDebt, {from: buyer});
    //     await purchaseContract.updatePayment({from: buyer});
    //     let state = await purchaseContract.phase.call({from: notary});
    //     assert.equal(state.toNumber(), 5);
    // })

    // it('allows buyer and seller sign', async function() {
    //     await purchaseContract.sign({from: seller});
    //     await purchaseContract.sign({from: buyer});
    //     let state = await purchaseContract.phase.call({from: notary});
    //     assert.equal(state.toNumber(), 6);
    // })

    // it('allows registar calificate the contract', async function() {
    //     await purchaseContract.qualify(false, {from: registrar});
    //     let state = await purchaseContract.phase.call({from: notary});
    //     assert.equal(state.toNumber(), 7);
    // })

    it('is not transfered', async function() {
        let newOwner = await property.owner.call({from: buyer});
        assert.equal(newOwner, seller, 'The ownersip transfer was not successful');
        console.log((await euroToken.balanceOf(seller)).toNumber() / 10000);
        console.log((await euroToken.balanceOf(buyer)).toNumber() / 10000);
        console.log((await euroToken.balanceOf(publicFinance.address)).toNumber() / 10000);
    })

})