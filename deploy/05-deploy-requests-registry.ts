import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const registryContractName = "RequestsRegistry";
  const proposalContractName = "Proposal";
  const proposal = locklift.factory.getContractArtifacts(proposalContractName);
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");

  await locklift.deployments.deploy({
    deployConfig: {
      contract: registryContractName,
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: {
        managerCollection: managerCollection.address,
        proposalCode: proposal.code,
      },
      value: toNano(4),
    },
    deploymentName: registryContractName,
    enableLogs: true,
  });
};

export const tag = "RequestsRegistry";
