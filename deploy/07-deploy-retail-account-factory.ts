import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const accountFactoryContractName = "RetailAccountFactory";
  const accountArtifacts = await locklift.factory.getContractArtifacts("RetailAccount");
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");
  const cardsRegistry = await locklift.deployments.getContract("CardsRegistry");
  const bank = await locklift.deployments.getContract("Bank");
  const requestsRegistry = await locklift.deployments.getContract("RequestsRegistry");
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");
  const initialAmount = 0;

  await locklift.deployments.deploy({
    deployConfig: {
      contract: accountFactoryContractName,
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: {
        code: accountArtifacts.code,
        cardsRegistry: cardsRegistry.address,
        bank: bank.address,
        requestsRegistry: requestsRegistry.address,
        managerCollection: managerCollection.address,
        initialAmount: initialAmount,
      },
      value: toNano(4),
    },
    deploymentName: accountFactoryContractName,
    enableLogs: true,
  });

  // TODO: deploy an account and add cards
};

export const tag = "Bank";
