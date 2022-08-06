require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
      },
    ],
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
  },
};
