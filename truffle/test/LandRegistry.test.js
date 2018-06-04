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

    before('setup landRegistry and events watchers', async function() {
        landRegistry = await LandRegistry.new('Comunidad Autonoma de Catalunya', 'Hospitalet II', 'Calle Inventada', {from: manager});
    })

    it('provides land registry basic info', async function() {
        let info = await landRegistry.getLandRegistryInfo({from: manager});
        assert.equal(info[0], 'Comunidad Autonoma de Catalunya', 'Error at getting the autonomous community');
        assert.equal(info[1], 'Hospitalet II', 'Error at getting the registry name');
        assert.equal(info[2], 'Calle Inventada', 'Error at getting the registry description');
        assert.equal(info[3], 0x0, 'Registrar should be null');
    })

    it('can be assigned with a registrar', async function() {
        await landRegistry.nameRegistrar(registrar, {from: manager});
        assert.equal(registrar, await landRegistry.getRegistrar({from: manager}), 'Couldn\' assign a registrar'); 
    })

    it('can allow a registrar to emit an entry', async function() {
        let newEntry = {
            code: 1, 
            property: notRealProperty,
            description: "Peticion de inscripción de una cancelacion de hipoteca",
            document: notRealDocument
        }
        let result = await landRegistry.registerEntry(newEntry.code, newEntry.property, newEntry.description, newEntry.document, {from: registrar});
        assert.equal(result.logs[0].args.description, newEntry.description, 'Something went wrong with registering the entry');
    })

    it('can register a property', async function() {
        let newProperty = {
            IDUFIR: 123,
            CRU: 456,
            description: 'Casa Margarita de la calle Dolores',
            owner: propertyOwner,
        }

        let result = await landRegistry.registerProperty(
            newProperty.IDUFIR,
            newProperty.CRU,
            newProperty.description,
            newProperty.owner,
            {from: registrar}
        );

        let property = await Property.at(result.logs[0].args.property);

        let propertyInfo = await property.getPropertyInfo({from: propertyOwner});

        assert.equal(newProperty.IDUFIR, propertyInfo[0], 'Wrong IDUFIR');
        assert.equal(newProperty.CRU, propertyInfo[1], 'Wrong CRU');
        assert.equal(newProperty.description, propertyInfo[2], 'Wrong description');
        assert.equal(newProperty.owner, propertyInfo[3], 'Wrong owner');

    })
    

})