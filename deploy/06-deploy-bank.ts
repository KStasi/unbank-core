import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const bankContractName = "Bank";
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");

  const randomNonce = new Date().getTime();

  await locklift.deployments.deploy({
    deployConfig: {
      contract: bankContractName,
      publicKey: signer.publicKey,
      initParams: {
        _randomNonce: randomNonce,
      },
      constructorParams: {
        owner: shareTokenRoot.address,
        chiefManagerCollection: chiefManagerCollection.address,
      },
      value: toNano(4),
    },
    deploymentName: bankContractName,
    enableLogs: true,
  });
  // TODO: add currencies
};

export const tag = "Bank";
