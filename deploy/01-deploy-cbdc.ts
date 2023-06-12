import { getRandomNonce, toNano, zeroAddress } from "locklift";
import BigNumber from "bignumber.js";

export default async () => {
  const signer = await locklift.keystore.getSigner("0");
  const founder1 = locklift.deployments.getAccount("Founder1").account;
  // const founder2 = locklift.deployments.getAccount("Founder2").account;
  // const founder3 = locklift.deployments.getAccount("Founder3").account;

  const tokensData = [
    {
      name: "Venom USD",
      symbol: "veUSD",
      initialSupply: 0,
      decimals: 9,
      deploymentName: "CBDC1",
      rootOwner: founder1.address,
    },
    {
      name: "Venom Euro",
      symbol: "veEUR",
      initialSupply: 0,
      decimals: 9,
      deploymentName: "CBDC2",
      rootOwner: founder1.address,
    },
    {
      name: "Venom Dirham",
      symbol: "veAED",
      initialSupply: 0,
      decimals: 9,
      deploymentName: "CBDC3",
      rootOwner: founder1.address,
    },
  ];

  for (let tokenData of tokensData) {
    const rootOwner = tokenData.rootOwner;
    const initialSupplyTo = rootOwner;
    const disableMint = false;
    const disableBurnByRoot = false;
    const pauseBurn = false;

    const tracing = await locklift.tracing.trace(
      locklift.deployments.deploy({
        deployConfig: {
          contract: "TokenRoot",
          publicKey: signer.publicKey,
          initParams: {
            deployer_: zeroAddress, // this field should be zero address if deploying with public key (see source code)
            randomNonce_: getRandomNonce(),
            rootOwner_: rootOwner,
            name_: tokenData.name,
            symbol_: tokenData.symbol,
            decimals_: tokenData.decimals,
            walletCode_: locklift.factory.getContractArtifacts("TokenWallet").code,
          },
          constructorParams: {
            initialSupplyTo: initialSupplyTo,
            initialSupply: new BigNumber(tokenData.initialSupply).shiftedBy(tokenData.decimals).toFixed(),
            deployWalletValue: toNano(0.3),
            mintDisabled: disableMint,
            burnByRootDisabled: disableBurnByRoot,
            burnPaused: pauseBurn,
            remainingGasTo: zeroAddress,
          },
          value: toNano(1.5),
        },
        deploymentName: tokenData.deploymentName, // user-defined custom name
        enableLogs: true,
      }),
      )
  }
};
export const tag = "CBDCs";
