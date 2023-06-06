import { Address, getRandomNonce, toNano, zeroAddress } from "locklift";
import BigNumber from "bignumber.js";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const rootOwner = new Address("0:0000000000000000000000000000000000000000000000000000000000000000");
  const rootContract = "ShareTokenRoot";
  const walletContract = "ShareTokenWallet";
  const name = "Share Token";
  const symbol = "veSHARE";
  const decimals = 18;

  const founder1 = locklift.deployments.getAccount("Founder1").account;
  const founder2 = locklift.deployments.getAccount("Founder2").account;
  const founder3 = locklift.deployments.getAccount("Founder3").account;

  const initialShares = [
    {
      owner: founder1.address,
      amount: toNano(toNano(1)),
    },
    {
      owner: founder2.address,
      amount: toNano(toNano(1000)),
    },
    {
      owner: founder3.address,
      amount: toNano(toNano(1000)),
    },
  ];

  const defaultQuorumRate = 5100; // e.g., 51%
  const lifetime = 15 * 24 * 3600; // e.g., 15 days

  const TokenWallet = locklift.factory.getContractArtifacts(walletContract);

  await locklift.deployments.deploy({
    deployConfig: {
      contract: rootContract,
      publicKey: signer.publicKey,
      initParams: {
        deployer_: zeroAddress,
        randomNonce_: getRandomNonce(),
        rootOwner_: rootOwner,
        name_: name,
        symbol_: symbol,
        decimals_: decimals,
        walletCode_: TokenWallet.code,
      },
      constructorParams: {
        defaultQuorumRate: defaultQuorumRate,
        lifetime: lifetime,
        initialShares: initialShares,
      },
      value: toNano(5),
    },
    deploymentName: rootContract,
    enableLogs: true,
  });
};
export const tag = "ShareTokenRoot";
