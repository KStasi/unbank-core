import { WalletTypes, toNano, getRandomNonce } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const registryContractName = "CardsRegistry";
  const debitContractName = "CardWithLimits";
  const savingContractName = "SavingCard";
  const debitCard = locklift.factory.getContractArtifacts(debitContractName);
  const savingCard = locklift.factory.getContractArtifacts(savingContractName);
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");

  const owner = chiefManagerCollection.address;

  const initialCards = [
    {
      id: 0,
      code: debitCard.code,
    },
    {
      id: 1,
      code: savingCard.code,
    },
  ];
  const tracing = await locklift.tracing.trace(
    locklift.deployments.deploy({
      deployConfig: {
        contract: registryContractName,
        publicKey: signer.publicKey,
        initParams: {
          _randomNonce: getRandomNonce(),
        },
        constructorParams: { initialCards, owner },
        value: toNano(0.3),
      },
      deploymentName: registryContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "CardsRegistry";
