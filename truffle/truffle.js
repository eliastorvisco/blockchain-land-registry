module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    dev: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Match any network id,
      gas: 3000000
    },
  }
};
