import { WalletTypes, toNano } from "locklift";

export type cbdcDetails = [
  Address,
  {
    CbdcInfo;
  },
];
export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  const bankContractName = "Bank";
  const shareTokenRoot = await locklift.deployments.getContract("ShareTokenRoot");
  const chiefManagerCollection = await locklift.deployments.getContract("ChiefManagerCollection");

  const cbdc1 = await locklift.deployments.getContract("CBDC1");
  // const cbdc2 = await locklift.deployments.getContract("CBDC2");
  // const cbdc3 = await locklift.deployments.getContract("CBDC3");

  const intialCbdcDetails = [
    [
      cbdc1.address,
      {
        isActive: true,
        defaultDailyLimit: toNano(100),
        defaultMonthlyLimit: toNano(1000),
      },
    ],
    // [
    //   cbdc2.address,
    //   {
    //     isActive: true,
    //     defaultDailyLimit: toNano(100),
    //     defaultMonthlyLimit: toNano(1000),
    //   },
    // ],
    // [
    //   cbdc3.address,
    //   {
    //     isActive: true,
    //     defaultDailyLimit: toNano(100),
    //     defaultMonthlyLimit: toNano(1000),
    //   },
    // ],
  ];

  const randomNonce = new Date().getTime();

  const tracing = await locklift.tracing.trace(
    locklift.deployments.deploy({
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
        value: toNano(3),
      },
      deploymentName: bankContractName,
      enableLogs: true,
    }),
  );
  // console.log(tracing);
};

export const tag = "Bank";
