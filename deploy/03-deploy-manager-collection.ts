import { WalletTypes, toNano, Address } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ManagerCollection";
  const metadata = `{"collection":"Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");
  const initialManagers = [
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000001"),
      manager: new Address("0:0000000000000000000000000000000000000000000000000000000000000001"),
      json: `{"role":"Chief Manager"}`,
    },
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000002"),
      manager: new Address("0:0000000000000000000000000000000000000000000000000000000000000002"),
      json: `{"role":"Chief Manager"}`,
    },
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000003"),
      manager: new Address("0:0000000000000000000000000000000000000000000000000000000000000003"),
      json: `{"role":"Chief Manager"}`,
    },
  ];

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
        initialManagers,
      },
      value: toNano(5),
    },
    deploymentName: collectionContractName,
    enableLogs: true,
  });
};

export const tag = "ManagerCollection";
