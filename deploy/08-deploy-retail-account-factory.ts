import { toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const accountFactoryContractName = "RetailAccountFactory";
  const accountArtifacts = await locklift.factory.getContractArtifacts("RetailAccount");
  const cardsRegistry = await locklift.deployments.getContract("CardsRegistry");
  const bank = await locklift.deployments.getContract("Bank");
  const requestsRegistry = await locklift.deployments.getContract("RequestsRegistry");
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");
  const initialAmount = toNano(1);

  const tracing = await locklift.tracing.trace(
    locklift.deployments.deploy({
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
        value: toNano(1),
      },
      deploymentName: accountFactoryContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "RetailAccountFactory";
