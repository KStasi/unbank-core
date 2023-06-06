import { WalletTypes, toNano } from "locklift";
import BigNumber from "bignumber.js";

export default async () => {
  const accountFactory = await locklift.deployments.getContract("RetailAccountFactory");
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");

  const managers = [
    locklift.deployments.getAccount("Manager1").account,
    locklift.deployments.getAccount("Manager2").account,
    locklift.deployments.getAccount("Manager3").account,
  ];

  const retailAccounts = [
    locklift.deployments.getAccount("RetailAccount1").account,
    locklift.deployments.getAccount("RetailAccount2").account,
    locklift.deployments.getAccount("RetailAccount3").account,
  ];
  const cbdcs = [
    locklift.deployments.getContract("CBDC1"),
    locklift.deployments.getContract("CBDC2"),
    locklift.deployments.getContract("CBDC3"),
  ];

  const cards = [
    { cardTypeId: 0, currency: cbdcs[0].address, otherCardDetails: "" },
    // { cardTypeId: 1, currency: cbdcs[0], otherCardDetails: "targetAmount" },
  ];

  BigNumber.config({ EXPONENTIAL_AT: 80 });

  for (let i = 0; i < managers.length; i++) {
    const manager = managers[i];
    const retailAccount = retailAccounts[i];

    const accountFactoryCallData = await accountFactory.methods
      .deployRetailAccount({
        pubkey: null,
        owner: retailAccount.address,
      })
      .encodeInternal();

    const managerCollectionCallData = await managerCollection.methods
      .callAsAnyManager({
        owner: manager.address,
        dest: accountFactory.address,
        value: toNano(0.1),
        bounce: false,
        flags: 0,
        payload: accountFactoryCallData,
      })
      .encodeInternal();

    const addressDetails = manager.address.toString().split(":");

    const { nft: nftAddress } = await managerCollection.methods
      .nftAddress({ id: new BigNumber(addressDetails[1], 16).toString(), answerId: 0 })
      .call();

    const managerNFTInstance = await locklift.factory.getDeployedContract("ManagerNftBase", nftAddress);

    const callResult = await managerNFTInstance.methods
      .sendTransaction({
        dest: managerCollection.address,
        value: toNano(0.1),
        bounce: false,
        flags: 0,
        payload: managerCollectionCallData,
      })
      .send({
        from: manager.address,
        amount: toNano(0.1),
      });

    console.log("Aborted: " + callResult.aborted);
    console.log("Exit code: " + callResult.exitCode);
    console.log("Result Code: " + callResult.resultCode);

    const { retailAccount: retailAccountAddress } = await accountFactory.methods
      .retailAccountAddress({ pubkey: null, owner: retailAccount.address, answerId: i })
      .call();

    console.log(retailAccount);

    const retailAccountInstance = await locklift.factory.getDeployedContract("RetailAccount", retailAccountAddress);

    for (let card of cards) {
      const addCardCallData = await retailAccountInstance.methods
        .addCard({
          cardTypeId: card.cardTypeId,
          currency: card.currency,
          otherCardDetails: card.otherCardDetails,
        })
        .encodeInternal();

      const managerCollectionCallData = await managerCollection.methods
        .callAsAnyManager({
          owner: manager.address,
          dest: accountFactory.address,
          value: toNano(0.1),
          bounce: false,
          flags: 0,
          payload: addCardCallData,
        })
        .encodeInternal();

      const callResult = await managerNFTInstance.methods
        .sendTransaction({
          dest: managerCollection.address,
          value: toNano(0.1),
          bounce: false,
          flags: 0,
          payload: managerCollectionCallData,
        })
        .send({
          from: manager.address,
          amount: toNano(0.1),
        });

      console.log("Aborted: " + callResult.aborted);
      console.log("Exit code: " + callResult.exitCode);
      console.log("Result Code: " + callResult.resultCode);
    }
  }
};

export const tag = "Deploy Retail Accounts";
