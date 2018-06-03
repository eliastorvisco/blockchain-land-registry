const EuroTokenBanking = artifacts.require('./EuroTokenBanking.sol');
const EuroToken = artifacts.require('./EuroToken.sol');
const SafeMath = artifacts.require('./SafeMath.sol');

module.exports = function(deployer) {
    deployer.deploy(SafeMath).then(() => {
        deployer.deploy(EuroToken);
    });
    deployer.link(SafeMath, EuroToken);

    deployer.deploy(SafeMath).then(() => {
        deployer.deploy(EuroTokenBanking);
    });
    deployer.link(SafeMath, EuroTokenBanking);
    
    

  };
  