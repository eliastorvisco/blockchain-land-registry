pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract EuroTokenBanking  is Owned {

    using SafeMath for uint;

    EuroToken public euroToken;

    event CashIn(address indexed receiver, uint256 amount);
    event CashOut(address indexed receiver, uint256 amount, string bankAccount);

    function EuroTokenBanking() public {
        euroToken = new EuroToken();
    }

    function cashIn(address to, uint tokens) public onlyOwner {
        euroToken.setBalance(to, euroToken.balanceOf(to).add(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().add(tokens));
        CashIn(to, tokens);
        
    }

    function cashOut(uint tokens, string bankAccount) public onlyOwner {
        euroToken.setBalance(msg.sender, euroToken.balanceOf(msg.sender).sub(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().sub(tokens));
        CashOut(msg.sender, tokens, bankAccount);
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract EuroToken is ERC20Interface, Owned {
 
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    function EuroToken() public {
        symbol = "EUR";
        name = "Euro Token";
        decimals = 4;
        _totalSupply = 0;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function setTotalSupply(uint newTotalSupply) public onlyOwner {
        _totalSupply = newTotalSupply;
    }
 
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function setBalance(address to, uint tokens) public onlyOwner {
        balances[to] = tokens;
        Transfer(this, to, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    // Transfer the balance from owner's account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
 
    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
 
    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
}

contract LandRegistry {

    struct PropertyRegister {
        address[] list;
        // mapping (address => address[]) byOwner //Why should we store this. If we want to know the property owner we can do it thorugh Property contract
    }

    struct LandRegistryInfo {
        string autonomousCommunity;
        string name;
        string description;
        address registrar;
        //string registrarPk;
    }

    struct AdminOrganizations {
        address justiceMinistry;
        address DGRN;
        address autonomousCommunity;
        address publicFinance;
    }

    PropertyRegister properties;
    LandRegistryInfo public landRegistry;
    AdminOrganizations public adminOrganizations;

    function LandRegistry(string _autonomousCommunityName, string _registryName, string _registryDescription, address _justiceMinistry, address _DGRN, address _autonomousCommunity, address _publicFinance) public {
        landRegistry = LandRegistryInfo({
            autonomousCommunity: _autonomousCommunityName,
            name: _registryName,
            description: _registryDescription,
            registrar: 0x0
        });

        adminOrganizations = AdminOrganizations({
            justiceMinistry: _justiceMinistry,
            DGRN: _DGRN,
            autonomousCommunity: _autonomousCommunity,
            publicFinance: _publicFinance
        });
    }

    /***********************************************
     *  Info getters
     */

    function getRegistrar() public view returns (address registrar) {
        return landRegistry.registrar;
    }

    function getLandRegistryInfo() public view returns (string autonomuousCommunity, string name, string description, address registrar) {
        return (
            landRegistry.autonomousCommunity,
            landRegistry.name,
            landRegistry.description,
            landRegistry.registrar
        );
    }

    function getAdminOrganizations() public view returns (address justiceMinistry, address DGRN, address autonomousCommunity, address publicFinance) {
        return (
            adminOrganizations.justiceMinistry,
            adminOrganizations.DGRN,
            adminOrganizations.autonomousCommunity,
            adminOrganizations.publicFinance
        );
    }

    /***********************************************
     *  Property Getters
     */

    function getAllProperties() public view returns (address[]) {
        return properties.list;
    }

    function getNumberOfProperties() public view returns (uint) {
        return properties.list.length;
    }

    function getPropertyAt(uint index) public view returns (address) {
        return properties.list[index];
    }

    // function getPropertiesAtRange(uint indexA, uint indexB) public returns (address[]) {
    //     require (indexA < indexB && indexA >= 0 && indexB >= 0);
    //     address[] storage tmp;
        
    //     for (uint i = indexA; i < indexB; i++) {
    //         tmp.push(properties.list[i]);
    //     }
    //     return tmp;
    // }

    // function getOwnerProperties(address owner) public view returns (address[]) {
    //     return properties.byOwner[owner];
    // }

    // function getOwnerPropertyAt(address owner, uint index) public view returns (address) {
    //     return properties.byOwner[owner][index];
    // }

    /***********************************************
     *  Land Registry Logics
     */

    function nameRegistrar(address _registrar) public {
        landRegistry.registrar = _registrar;
    }

    function registerProperty(uint IDUFIR, uint CRU, string description, address owner) public {
        Property property = new Property(IDUFIR, CRU, description, owner, this); 
        properties.list.push(address(property));
    }
}

contract Property {

    struct PropertyInfo {
        uint IDUFIR;
        uint CRU;
        string description;
        address owner;
    }

    struct AdministrativeInfo {
        address registry;
    }

    struct TransfershipInfo {
        bool transferingState;
        address purchaseContract;
    }

    PropertyInfo public propertyInfo;
    AdministrativeInfo public adminInfo;
    TransfershipInfo public transfer;


    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _registry) public {

        propertyInfo = PropertyInfo ({
            IDUFIR: _IDUFIR,
            CRU: _CRU,
            description: _description,
            owner: _owner
        });

        adminInfo = AdministrativeInfo({
            registry: _registry
        });

        transfer = TransfershipInfo({
            transferingState: false,
            purchaseContract: 0x0
        });
    }

    /***********************************************
     *  Property Getters
     */

    function getIDUFIR() public view returns (uint IDUFIR) {return propertyInfo.IDUFIR;}
    function getCRU() public view returns (uint CRU) {return propertyInfo.CRU;}
    function getDescription() public view returns (string description) {return propertyInfo.description;}
    function getOwner() public view returns (address owner) {return propertyInfo.owner;}

    function getPropertyInfo() public view returns (uint IDUFIR, uint CRU, string description, address owner) {
        return (
            propertyInfo.IDUFIR,
            propertyInfo.CRU,
            propertyInfo.description,
            propertyInfo.owner
        );
    }
    

    function getAdministrativeInfo() public view returns (address registry) {
        return (
            adminInfo.registry
        );
    }
    
    function getTransfershipInfo() public view returns (bool transferingState, address purchaseContract) {
        return (
            transfer.transferingState,
            transfer.purchaseContract
        );
    }

    /***********************************************
     *  Property Logics
     */

    function createPurchaseContract(uint price, address euroToken) onlyOwner public {
        require(transfer.purchaseContract == address(0));
        transfer = TransfershipInfo({
            transferingState: true,
            purchaseContract: new PurchaseContract(this, price, propertyInfo.owner, LandRegistry(adminInfo.registry).getRegistrar(), euroToken)
        });
    }

    function transferOwnership(address from, address to) public {
        require(msg.sender == transfer.purchaseContract);
        require(from == propertyInfo.owner);

        propertyInfo.owner = to;
        transfer = TransfershipInfo({
            transferingState: false,
            purchaseContract: 0x0
        });
    }

    modifier onlyOwner() {
        require(msg.sender == propertyInfo.owner);
        _;
    }
}

contract PurchaseContract {
    // Property Info

    event PhaseChanged(uint oldPhase, uint newPhase);
    event Signed(address from, bool signature);
    event Paid(address from, uint paid);
    event Calificated(address property, bool calification, address oldOwner, address newOwner);

    enum Phases { Join, Writting, Validation, Paying, Signing, Calificating, Finished }
    Phases public phase;

    EuroToken public euroToken;

    address public property;
    uint public price;    
    string public contractHash;
   

    struct ContractParticipant {
        address addr;
        uint debt;
        bool hasValidated;
        bool contractValidation;
        bool hasSigned;
        bool signature;
    }

    struct Registrar {
        address addr;
        bool hasCalificated;
        bool calification;
    }

    struct Notary {
        address addr;
    }

    ContractParticipant public seller;
    ContractParticipant public buyer;
    Notary public notary;
    Registrar public registrar;

    function PurchaseContract(address _property, uint _price, address _seller, address _registrar, address _euroToken) public {
        require(Property(_property).getOwner() == _seller);
        property = _property;
        price = _price;
        seller.addr = _seller;
        buyer.debt = _price;
        registrar.addr = _registrar;
        euroToken = EuroToken(_euroToken);
    }

    /***********************************************
    *  Phase Functions
    */

    function changePhase(Phases newPhase) internal {
        PhaseChanged(uint(phase), uint(newPhase));
        phase = newPhase;
    } 

    /***********************************************
     *  Phase: Join
     */

    function addBuyer(address _buyer) public onlyWhen(Phases.Join) onlySeller {
        buyer.addr = _buyer;
    }

    function addNotary(address _notary) public onlyWhen(Phases.Join) onlyBuyer {
        notary.addr = _notary;
        changePhase(Phases.Writting);
    }

    /***********************************************
     *  Phase.Writting
     */

    function setContractHash(string hash) public onlyNotary onlyWhen(Phases.Writting) {
        require(bytes(hash).length != 0);
        contractHash = hash;
        changePhase(Phases.Validation);
    }

    /***********************************************
     *  Phase.Validation
     */

    function validateContractDocument(string hash) public onlySellerOrBuyer onlyWhen(Phases.Validation) {

        if (keccak256(contractHash) == keccak256(hash)) {
            if (isSeller()) seller.contractValidation = true;
            else if (isBuyer()) buyer.contractValidation = true;
        } else {}

        if (seller.contractValidation && buyer.contractValidation) {
            changePhase(Phases.Paying);
        }
    }

    /***********************************************
     *  Phase.Paying
     */

    function updatePayment() public onlySellerOrBuyer onlyWhen(Phases.Paying) {
        Paid(msg.sender, euroToken.allowance(msg.sender, this));
        if (euroToken.allowance(buyer.addr, this) == buyer.debt && euroToken.allowance(seller.addr, this) == seller.debt) {
            changePhase(Phases.Signing);
        }
    }

    /***********************************************
     *  Phase.Signing
     */

    function sign(bool _signature) public onlySellerOrBuyer onlyWhen(Phases.Signing) {
        
        if (isSeller()) {
            require(!seller.hasSigned);
            seller.signature = _signature;
            seller.hasSigned = true;
        } else if (isBuyer()) {
            require(!buyer.hasSigned);
            buyer.signature = _signature;
            buyer.hasSigned = true;
        }

        Signed(msg.sender, _signature);

        if (buyer.hasSigned && buyer.signature && seller.hasSigned && seller.signature) {
            changePhase(Phases.Calificating);
        }
    }

    /***********************************************
     *  Phase.Calificating
     */

    function calificate(bool _calification) public onlyRegistrar onlyWhen(Phases.Calificating) {
        registrar.calification = _calification;
        registrar.hasCalificated = true;
        changePhase(Phases.Finished);
        if (_calification) {
            Property(property).transferOwnership(seller.addr, buyer.addr);
            euroToken.transferFrom(buyer.addr, seller.addr, buyer.debt);
        }
        Calificated(property, _calification, seller.addr, buyer.addr);
    }

    /***********************************************
     *  Auxiliar Functions
     */

    function isBuyer() internal view returns (bool) {return (msg.sender == buyer.addr);}
    function isSeller() internal view returns (bool) {return (msg.sender == seller.addr);}
    function isNotary() internal view returns (bool) {return (msg.sender == notary.addr);}
    function isRegistrar() internal view returns (bool) {return (msg.sender == registrar.addr);}

    /***********************************************
     *  Modifiers
     */

    modifier onlySellerOrBuyer() {require(isSeller() || isBuyer()); _;}
    modifier onlyBuyer() {require(isBuyer()); _;}
    modifier onlySeller() {require(isSeller()); _;}
    modifier onlyNotary() {require(isNotary()); _;}
    modifier onlyRegistrar() {require(isRegistrar()); _;}
    modifier onlyWhen(Phases strictPhase) {require(phase == strictPhase); _;}
    /***********************************************
    *  Info Getters
    */
    
    function getSellerSummary() public view returns (address addr, uint debt, uint paid, bool contractValidation, bool hasSigned, bool signature) {
        return (
            seller.addr,
            seller.debt,
            (phase > Phases.Paying)? seller.debt: euroToken.allowance(seller.addr, this),
            seller.contractValidation,
            seller.hasSigned,
            seller.signature
        );
    }

    function getBuyerSummary() public view returns (address addr, uint debt, uint paid, bool contractValidation, bool hasSigned, bool signature) {
        return (
            buyer.addr,
            buyer.debt,
            (phase > Phases.Paying)? buyer.debt: euroToken.allowance(buyer.addr, this),
            buyer.contractValidation,
            buyer.hasSigned,
            buyer.signature
        );
    }

    function getContractSummary() public view returns (uint currentPhase, bool contractWritten, bool hasBeenCalificated, bool calification) {
        return(
            uint(phase),
            (bytes(contractHash).length > 0),
            registrar.hasCalificated,
            registrar.calification
        );
    }
}


