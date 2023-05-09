import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x06edcf9c92fb99b14bcf0a7f016b3f298548425df085483c1d1a68aecae4b4a9",
    lootMarketArcade:
      "0x058899f75e139dd3db67fa6e875c79a12a48328215d93dd688721750389300f8",
    beast: "0x029887bb51387e152aa861f8378e004fad6f99db836293855184540c08072731",
    lords_erc20_mintable:
      "0x017441a8855b221aacb4b4ece57b0665b91ac41fd7d03e481fcd40767c17708d",
  },
  goerli: {
    adventurer:
      "0x045c00857eba10068c8cc54b438eb769735c679fd7af14815a7bf771f1d81ef6",
    lootMarketArcade:
      "0x01db417426a5e190e328953e3bc36a2cfe4516743ff02c05c3a904107a1ad180",
    beast: "0x07c93d30731ebe1cd8d3dd2ee92917205f6c136b24f317b3de87e8c93da45ceb",
    lords_erc20_mintable:
      "0x0270a44f4bcfa1815015272a56929230c12f64eae91316909b5f9fe945a6332f",
  },
};

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.adventurer
        : contracts.goerli.adventurer,
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.lootMarketArcade
        : contracts.goerli.lootMarketArcade,
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.beast
        : contracts.goerli.beast,
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.lords_erc20_mintable
        : contracts.goerli.lords_erc20_mintable,
    abi: Lords_ERC20_Mintable,
  });

  return {
    adventurerContract,
    lootMarketArcadeContract,
    beastContract,
    lordsContract,
  };
};
