import { Address, toNano, WalletTypes } from "locklift";
import BigNumber from "bignumber.js";

const USER_ADDRESS = new Address("0:5368ceef99d6ce85728bc9924d8ceed46b30441d3f9efaf42853a3a6af3d46d0");
const MANAGER_COLLECTION_ADDRESS = new Address("0:e6d197baf1fa3a89a3f7aea2b8dcab2bf149bbd6481936743b6dd3b67f1d7474");
const ACCOUNT_FACTORY_ADDRESS = new Address("0:8b7ed9bab4f407c27dbd5e4a9796806eab09cdf14a5f9e95f883da0200c1aaae");
const MANAGER_ADDRESS = new Address("0:cc0b13c55a8901fd1ed9332be3f6d925cfd309f1997ef3724467680c39342822");

async function main() {
  const someAccount = await locklift.factory.accounts.addExistingAccount({
    type: WalletTypes.EverWallet,
    address: MANAGER_ADDRESS,
  });

  const accountFactory = await locklift.factory.getDeployedContract("RetailAccountFactory", ACCOUNT_FACTORY_ADDRESS);
  const managerCollection = await locklift.factory.getDeployedContract("ManagerCollection", MANAGER_COLLECTION_ADDRESS);

  const retailAccountAddress = await accountFactory.methods
    .retailAccountAddress({ pubkey: null, owner: USER_ADDRESS, answerId: 2 })
    .call();

  console.log(retailAccountAddress);
  const accountFactoryCallData = await accountFactory.methods
    .deployRetailAccount({
      pubkey: null,
      owner: USER_ADDRESS,
    })
    .encodeInternal();

  const managerCollectionCallData = await managerCollection.methods
    .callAsAnyManager({
      owner: MANAGER_ADDRESS,
      dest: accountFactory.address,
      value: toNano(1),
      bounce: false,
      flags: 0,
      payload: accountFactoryCallData,
    })
    .encodeInternal();

  BigNumber.config({ EXPONENTIAL_AT: 120 });

  const addressDetails = MANAGER_ADDRESS.toString().split(":");
  const { nft: nftAddress } = await managerCollection.methods
    .nftAddress({ id: new BigNumber(addressDetails[1], 16).toString(), answerId: 0 })
    .call();

  const managerNFTInstance = await locklift.factory.getDeployedContract("ManagerNftBase", nftAddress);

  const tracing = await locklift.tracing.trace(
    managerNFTInstance.methods
      .sendTransaction({
        dest: managerCollection.address,
        value: toNano(2),
        bounce: false,
        flags: 0,
        payload: managerCollectionCallData,
      })
      .send({
        from: MANAGER_ADDRESS,
        amount: toNano(3),
      }),
  );
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
