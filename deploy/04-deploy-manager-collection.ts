import { WalletTypes, toNano, Address, getRandomNonce } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ManagerCollection";
  const metadata = `{"collection":"Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");

  const chiefManager1 = locklift.deployments.getAccount("ChiefManager1").account;
  // const chiefManager2 = locklift.deployments.getAccount("ChiefManager2").account;
  // const chiefManager3 = locklift.deployments.getAccount("ChiefManager3").account;
  const manager1 = locklift.deployments.getAccount("Manager1").account;
  // const manager2 = locklift.deployments.getAccount("Manager2").account;
  // const manager3 = locklift.deployments.getAccount("Manager3").account;

  const initialManagers = [
    {
      owner: manager1.address,
      manager: chiefManager1.address,
      json: `{"role":"Chief Manager"}`,
    },
    // {
    //   owner: manager2.address,
    //   manager: chiefManager2.address,
    //   json: `{"role":"Chief Manager"}`,
    // },
    // {
    //   owner: manager3.address,
    //   manager: chiefManager3.address,
    //   json: `{"role":"Chief Manager"}`,
    // },
  ];
  const tracing = await locklift.tracing.trace(
    locklift.deployments.deploy({
      deployConfig: {
        contract: collectionContractName,
        publicKey: signer.publicKey,
        initParams: {
          _randomNonce: getRandomNonce(),
        },
        constructorParams: {
          codeNft: nftArtifacts.code,
          codeIndex: indexArtifacts.code,
          codeIndexBasis: indexBasisArtifacts.code,
          json: metadata,
          admin: chiefManagerCollection.address,
          initialManagers,
        },
        value: toNano(4),
      },
      deploymentName: collectionContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "ManagerCollection";
