import { WalletTypes, toNano, getRandomNonce } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const registryContractName = "RequestsRegistry";
  const proposalContractName = "Proposal";
  const proposal = locklift.factory.getContractArtifacts(proposalContractName);
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");

  const tracing = await locklift.tracing.trace(
    locklift.deployments.deploy({
      deployConfig: {
        contract: registryContractName,
        publicKey: signer.publicKey,
        initParams: {
          _randomNonce: getRandomNonce(),
        },
        constructorParams: {
          managerCollection: managerCollection.address,
          proposalCode: proposal.code,
        },
        value: toNano(0.3),
      },
      deploymentName: registryContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "RequestsRegistry";
