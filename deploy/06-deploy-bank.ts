import { WalletTypes, toNano } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const bankContractName = "Bank";
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");
  const intialCbdcDetails = {
    cbdcAddress1: {
      isActive: true,
      defaultDailyLimit: toNano(100),
      defaultMonthlyLimit: toNano(1000),
    },
    cbdcAddress2: {
      isActive: true,
      defaultDailyLimit: toNano(100),
      defaultMonthlyLimit: toNano(1000),
    },
    cbdcAddress3: {
      isActive: true,
      defaultDailyLimit: toNano(100),
      defaultMonthlyLimit: toNano(1000),
    },
  };

  const randomNonce = new Date().getTime();

  await locklift.deployments.deploy({
    deployConfig: {
      contract: bankContractName,
      publicKey: signer.publicKey,
      initParams: {
        _randomNonce: randomNonce,
      },
      constructorParams: {
        owner: shareTokenRoot.address,
        chiefManagerCollection: chiefManagerCollection.address,
        cbdcDetails: intialCbdcDetails,
      },
      value: toNano(4),
    },
    deploymentName: bankContractName,
    enableLogs: true,
  });
  // TODO: add currencies
};

export const tag = "Bank";
