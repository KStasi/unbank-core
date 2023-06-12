import { WalletTypes, toNano } from "locklift";
import BigNumber from "bignumber.js";

export default async () => {
  const accountFactory = await locklift.deployments.getContract("RetailAccountFactory");
  const managerCollection = await locklift.deployments.getContract("ManagerCollection");

  const founders = [
    locklift.deployments.getAccount("Founder1").account,
    // locklift.deployments.getAccount("Founder2").account,
    // locklift.deployments.getAccount("Founder3").account,
  ];
  const managers = [
    locklift.deployments.getAccount("Manager1").account,
    // locklift.deployments.getAccount("Manager2").account,
    // locklift.deployments.getAccount("Manager3").account,
  ];

  const retailAccounts = [
    locklift.deployments.getAccount("RetailAccount1").account,
    // locklift.deployments.getAccount("RetailAccount2").account,
    // locklift.deployments.getAccount("RetailAccount3").account,
  ];
  const cbdcs = [
    locklift.deployments.getContract("CBDC1"),
    // locklift.deployments.getContract("CBDC2"),
    // locklift.deployments.getContract("CBDC3"),
  ];

  const cards = [
    { cardTypeId: 0, currency: cbdcs[0].address, cardType: 0, otherCardDetails: "" },
    // { cardTypeId: 1, currency: cbdcs[0], otherCardDetails: "targetAmount" },
  ];

  // address cardFrom;
  // address receiver;
  // uint128 amount;
  // uint32 period;
  // uint32 nextPayment;
  const automations = [
    { cardFrom: 0, receiver: founders[0].address, amount: toNano(0.1), period: 3600, nextPayment: 0 }
  ];

  BigNumber.config({ EXPONENTIAL_AT: 120 });

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
        value: toNano(0.5),
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

    const tracing = await locklift.tracing.trace(
      managerNFTInstance.methods
        .sendTransaction({
          dest: managerCollection.address,
          value: toNano(0.8),
          bounce: false,
          flags: 0,
          payload: managerCollectionCallData,
        })
        .send({
          from: manager.address,
          amount: toNano(1),
        }),
    );

    const { retailAccount: retailAccountAddress } = await accountFactory.methods
      .retailAccountAddress({ pubkey: null, owner: retailAccount.address, answerId: i })
      .call();

    const retailAccountInstance = await locklift.factory.getDeployedContract("RetailAccount", retailAccountAddress);

    for (let card of cards) {
      const addCardCallData = await retailAccountInstance.methods
        .addCard({
          cardTypeId: card.cardTypeId,
          currency: card.currency,
          cardType: card.cardType,
          otherCardDetails: card.otherCardDetails,
        })
        .encodeInternal();

      const managerCollectionCallData = await managerCollection.methods
        .callAsAnyManager({
          owner: manager.address,
          dest: retailAccountInstance.address,
          value: toNano(1.2),
          bounce: false,
          flags: 0,
          payload: addCardCallData,
        })
        .encodeInternal();
      const tracing = await locklift.tracing.trace(
        managerNFTInstance.methods
          .sendTransaction({
            dest: managerCollection.address,
            value: toNano(1.3),
            bounce: false,
            flags: 0,
            payload: managerCollectionCallData,
          })
          .send({
            from: manager.address,
            amount: toNano(1.4),
          }),
      );
      // console.log(tracing);
      const cardAddresses = (await retailAccountInstance.methods._cards().call())._cards.map((card) => card[0]);

      for (let automation of automations) {
        const tracing = await locklift.tracing.trace(retailAccountInstance.methods
          .addAutopayment({autopayment:{
            cardFrom: cardAddresses[automation.cardFrom],
            receiver: automation.receiver,
            amount: automation.amount,
            period: automation.period,
            nextPayment: automation.nextPayment,
          }}).send({
              from: retailAccount.address,
              amount: toNano(0.1),
            }));
        // console.log(tracing);
      }
    }
  }
};

export const tag = "Deploy Retail Accounts";
