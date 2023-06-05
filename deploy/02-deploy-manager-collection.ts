import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ManagerCollection";
  const metadata = `{"collection":"Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");

  // TODO: give initial roles
  await locklift.deployments.deploy({
    deployConfig: {
      contract: collectionContractName,
      publicKey: signer.publicKey,
      initParams: {},
      constructorParams: {
        codeNft: nftArtifacts.code,
        codeIndex: indexArtifacts.code,
        codeIndexBasis: indexBasisArtifacts.code,
        json: metadata,
        admin: chiefManagerCollection.address,
      },
      value: toNano(5),
    },
    deploymentName: collectionContractName,
    enableLogs: true,
  });
};

export const tag = "ManagerCollection";
