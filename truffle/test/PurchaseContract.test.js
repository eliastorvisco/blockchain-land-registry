const PurchaseContract = artifacts.require('./PurchaseContract.sol');
const LandRegistry = artifacts.require('./LandRegistry.sol');
const Property = artifacts.require('./Property.sol');
const EuroTokenBanking = artifacts.require('./EuroTokenBanking.sol');
const EuroToken = artifacts.require('./EuroToken.sol');

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
    
    let lRInfo = {
        name: 'Hospitalet de Llobregat, L\' Nº 02',
        addressInfo: 'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
        province: 'Barcelona',
        telephone: '(93)475 26 85',
        fax: '(93)475 26 86',
        email: 'hospitalet2registrodelapropiedad.org'
    }

    before('setup land registry and property', async function() {
        console.log('Prueba');
        bank = await EuroTokenBanking.new({from: manager});
        euroToken = await EuroToken.at(await bank.euroToken.call({from: manager}));
        await bank.cashIn(seller, 2000000000, {from: manager});
        await bank.cashIn(buyer,  2000000000, {from: manager});

        landRegistry = await LandRegistry.new(
           lRInfo.name,
           lRInfo.addressInfo,
           lRInfo.province,
           lRInfo.telephone,
           lRInfo.fax,
           lRInfo.email
        , {from: manager});
        await landRegistry.setRegistrar(registrar, {from: manager});

        property = await Property.new(1234, 1234, 'Calle Joan Maragall', seller, landRegistry.address, {from: registrar});
        console.log('Property Created: ', property.address);
        await landRegistry.register(property.address, 34578, 'New Registration',  fakeDocument, {from: registrar});
        console.log('Property registration state: ', await landRegistry.isRegistered.call(property.address, {from: registrar}));
        
        purchaseContract = await PurchaseContract.new(property.address, 1000000000, euroToken.address, {from: seller});
        
        await property.setPurchaseContract(purchaseContract.address, {from: seller});
        
        let sellerSummary = await purchaseContract.getSellerSummary({from: seller});
        console.log('Seller Summary: ', sellerSummary);

    })

    it('allows seller add a buyer', async function() {
        await purchaseContract.addBuyer(buyer, {from: seller});
        let buyerInfo = await purchaseContract.buyer.call({from: seller});
        console.log(buyerInfo);
    })

    it('allows buyer add a notary', async function() {
        await purchaseContract.addNotary(notary, {from: buyer});
        let notaryInfo = await purchaseContract.notary.call({from: buyer});
        console.log(notaryInfo);
        let state = await purchaseContract.phase.call({from: notary});
        console.log(state);
    })

    it('allows notary set a contract hash', async function() {
        let initialPhase = await purchaseContract.phase.call({from: notary});
        await purchaseContract.setContractHash('0xinvented', {from: notary});
        let finalPhase = await purchaseContract.phase.call({from: notary});
        let hash = await purchaseContract.contractHash.call({from: notary});

        console.log('Initial phase: ', initialPhase);
        console.log('Final phase: ', finalPhase);
        console.log(hash);
    })

    it('allows buyer and seller to validate the contract hash', async function() {
        let initialPhase = await purchaseContract.phase.call({from: notary});
        await purchaseContract.validateContractDocument('0xinvented', {from: buyer});
        await purchaseContract.validateContractDocument('0xinvented', {from: seller});
        let finalPhase = await purchaseContract.phase.call({from: notary});

        console.log('Initial phase: ', initialPhase);
        console.log('Final phase: ', finalPhase);
    })

    it('allows buyer pay', async function() {
        await euroToken.approve(purchaseContract.address, 1000000000, {from: buyer});
        await purchaseContract.updatePayment({from: buyer});
    })

    it('allows buyer and seller sign', async function() {
        let initialPhase = await purchaseContract.phase.call({from: notary});
        await purchaseContract.sign(true, {from: seller});
        await purchaseContract.sign(true, {from: buyer});
        let finalPhase = await purchaseContract.phase.call({from: notary});

        console.log('Initial phase: ', initialPhase);
        console.log('Final phase: ', finalPhase);
    })

    it('allows registar calificate the contract', async function() {
        let initialPhase = await purchaseContract.phase.call({from: notary});
        
        await purchaseContract.calificate(true, {from: registrar});

        let finalPhase = await purchaseContract.phase.call({from: notary});

        console.log('Initial phase: ', initialPhase);
        console.log('Final phase: ', finalPhase);
    })

    it('is transfered', async function() {
        let newOwner = await property.owner.call({from: buyer});
        assert.equal(newOwner, buyer, 'The ownersip transfer was not successful');
    })

})