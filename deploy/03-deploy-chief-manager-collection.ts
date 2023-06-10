import { WalletTypes, toNano, Address, getRandomNonce } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const collectionContractName = "ChiefManagerCollection";
  const metadata = `{"collection":"Chief Manager Roles"}`;
  const nftArtifacts = await locklift.factory.getContractArtifacts("ManagerNftBase");
  const indexArtifacts = await locklift.factory.getContractArtifacts("Index");
  const indexBasisArtifacts = await locklift.factory.getContractArtifacts("IndexBasis");
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");

  const chiefManager1 = locklift.deployments.getAccount("ChiefManager1").account;
  // const chiefManager2 = locklift.deployments.getAccount("ChiefManager2").account;
  // const chiefManager3 = locklift.deployments.getAccount("ChiefManager3").account;

  const initialChiefManagers = [
    {
      owner: chiefManager1.address,
      json: `{"role":"Chief Manager"}`,
    },
    // {
    //   owner: chiefManager2.address,
    //   json: `{"role":"Chief Manager"}`,
    // },
    // {
    //   owner: chiefManager3.address,
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
          admin: shareTokenRoot.address,
          initialChiefManagers,
        },
        value: toNano(1.2),
      },
      deploymentName: collectionContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "ChiefManagerCollection";
