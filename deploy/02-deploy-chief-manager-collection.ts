import { WalletTypes, toNano, Address } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ChiefManagerCollection";
  const metadata = `{"collection":"Chief Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");
  const initialChiefManagers = [
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000001"),
      json: `{"role":"Chief Manager"}`,
    },
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000002"),
      json: `{"role":"Chief Manager"}`,
    },
    {
      owner: new Address("0:0000000000000000000000000000000000000000000000000000000000000003"),
      json: `{"role":"Chief Manager"}`,
    },
  ];

  await locklift.deployments
    .deploy({
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
          initialChiefManagers,
        },
        value: toNano(5),
      },
      deploymentName: collectionContractName,
      enableLogs: true,
    })
    .catch(console.log);
};

export const tag = "ChiefManagerCollection";