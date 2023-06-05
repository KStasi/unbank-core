import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const registryContractName = "CardsRegistry";

  // TODO: add cards
  await locklift.deployments.deploy({
    deployConfig: {
      contract: registryContractName,
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: {},
      value: toNano(1),
    },
    deploymentName: registryContractName,
    enableLogs: true,
  });
};

export const tag = "CardsRegistry";
