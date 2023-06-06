import { Address, getRandomNonce, toNano, zeroAddress, WalletTypes } from "locklift";
import BigNumber from "bignumber.js";

export default async () => {
  // Prepare accounts settings
  const accountSettings = {
    type: WalletTypes.EverWallet,
    value: locklift.utils.toNano(2),
  };

  // Build accounts to deploy
  const accountsToDeploy = [
    ...Array.from({ length: 3 }, (_, i) => ({
      deploymentName: `Founder${i + 1}`,
      signerId: `${i}`,
      accountSettings,
    })),
    ...Array.from({ length: 3 }, (_, i) => ({
      deploymentName: `ChiefManager${i + 1}`,
      signerId: `${i + 3}`,
      accountSettings,
    })),
    ...Array.from({ length: 3 }, (_, i) => ({
      deploymentName: `Manager${i + 1}`,
      signerId: `${i + 6}`,
      accountSettings,
    })),
    ...Array.from({ length: 3 }, (_, i) => ({
      deploymentName: `RetailUser${i + 1}`,
      signerId: `${i + 9}`,
      accountSettings,
    })),
  ];
  console.log(accountsToDeploy);
  // Deploy all accounts
  await locklift.deployments.deployAccounts(accountsToDeploy, true);
};
export const tag = "Accounts";
