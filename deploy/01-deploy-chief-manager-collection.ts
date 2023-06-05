import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ChiefManagerCollection";
  const metadata = `{"collection":"Chief Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");

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
        admin: shareTokenRoot.address,
      },
      value: toNano(5),
    },
    deploymentName: collectionContractName,
    enableLogs: true,
  });
};

export const tag = "ChiefManagerCollection";
