import { WalletTypes } from "locklift";

export default async () => {
  const signer = (await locklift.keystore.getSigner("0"))!;
  await locklift.deployments.deployAccounts(
    [
      {
        deploymentName: "CBDCOwner",
        signerId: "0",
        accountSettings: {
          type: WalletTypes.EverWallet,
          value: locklift.utils.toNano(2),
        },
      },
    ],
    true, // enableLogs
  );
};
export const tag = "sample1";
