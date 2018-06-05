const LandRegistry = artifacts.require('./LandRegistry.sol');
const Property = artifacts.require('./Property.sol');

contract('LandRegistry', function(accounts) {

    let manager = accounts[0];
    let registrar = accounts[1];
    let notAllowedPerson = accounts[2];
    let notRealProperty = accounts[3];
    let notRealDocument = accounts[4];
    let propertyOwner = accounts[5];
    let landRegistry;
    let lRInfo = {
        name: 'Hospitalet de Llobregat, L\' Nº 02',
        addressInfo: 'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
        province: 'Barcelona',
        telephone: '(93)475 26 85',
        fax: '(93)475 26 86',
        email: 'hospitalet2registrodelapropiedad.org'
    }

    before('setup landRegistry and events watchers', async function() {

        landRegistry = await LandRegistry.new(
           lRInfo.name,
           lRInfo.addressInfo,
           lRInfo.province,
           lRInfo.telephone,
           lRInfo.fax,
           lRInfo.email
        , {from: manager});

    })

    it('provides land registry basic info', async function() {
        let info = await landRegistry.getLandRegistryInfo({from: manager});
        console.log(info);
        // assert.equal(info[0], 'Comunidad Autonoma de Catalunya', 'Error at getting the autonomous community');
        // assert.equal(info[1], 'Hospitalet II', 'Error at getting the registry name');
        // assert.equal(info[2], 'Calle Inventada', 'Error at getting the registry description');
        // assert.equal(info[3], 0x0, 'Registrar should be null');
    })

    it('can be assigned with a registrar', async function() {
        await landRegistry.setRegistrar(registrar, {from: manager});
        assert.equal(registrar, await landRegistry.registrar.call({from: manager}), 'Couldn\' assign a registrar'); 
    })

    it('can allow a registrar register a presentation entry', async function() {
        let newEntry = {
            identifier: 34576, 
            description: "Peticion de inscripción de una cancelacion de hipoteca",
            document: notRealDocument
        }
        let result = await landRegistry.addPresentationEntry(newEntry.identifier, newEntry.description, newEntry.document, {from: registrar});
        assert.equal(result.logs[0].args.document, newEntry.document, 'Something went wrong with registering the entry');
    })

    it('allows the registrar to create a property smart contract', async function() {
        let newProperty = {
            IDUFIR: 123,
            CRU: 456,
            description: 'Casa Margarita de la calle Dolores',
            owner: propertyOwner,
        }
        let result = await landRegistry.createProperty(
            newProperty.IDUFIR, 
            newProperty.CRU, 
            newProperty.description, 
            newProperty.owner
        ,{from: registrar});

        property = await Property.at(result.logs[0].args.property);

        assert.equal(propertyOwner, await property.owner.call(), 'Error')
    })

    it('allows the registrar to register a property', async function() {
        let isRegisteredBefore = await landRegistry.isRegistered.call(property.address, {from: propertyOwner});
        let newRegistration = {
            property: property.address,
            identifier: 3425786,
            description: 'First Registration of a Property',
            document: notRealDocument
        }
        let registrationInfo = await landRegistry.register(
            newRegistration.property, 
            newRegistration.identifier, 
            newRegistration.description, 
            newRegistration.document
        , {from: registrar});
        let isRegisteredAfter = await landRegistry.isRegistered.call(property.address, {from: propertyOwner});
        
        assert.equal(isRegisteredBefore, false, 'It shouldn\'t be registered');
        assert.equal(isRegisteredAfter, true, 'It should be registered')
    })

})