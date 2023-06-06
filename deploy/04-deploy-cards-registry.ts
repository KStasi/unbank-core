import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const registryContractName = "CardsRegistry";
  const debitContractName = "CardWithLimits";
  const savingContractName = "SavingCard";
  const debitCard = locklift.factory.getContractArtifacts(debitContractName);
  const savingCard = locklift.factory.getContractArtifacts(savingContractName);

  const initialCards = [
    {
      id: 1,
      code: debitCard.code,
    },
    {
      id: 2,
      code: savingCard.code,
    },
  ];

  await locklift.deployments.deploy({
    deployConfig: {
      contract: registryContractName,
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: { initialCards },
      value: toNano(1),
    },
    deploymentName: registryContractName,
    enableLogs: true,
  });
};

export const tag = "CardsRegistry";
