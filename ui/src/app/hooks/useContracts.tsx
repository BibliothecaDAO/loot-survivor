import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x00473b70f183c27ab4dac4139c39f364244ae89680810ff7f1f8cb6d754b2067",
    lootMarketArcade:
      "0x043d77e798f65a5284b4fde31051ee3b80f74a73817f607958e65d7504684ea0",
    beast: "0x0128dc5af5038e745c83c57230a3203cce571f90320042e295744763953c0306",
    lords_erc20_mintable:
      "0x0171f44786f43f8c8ac26595385c3dedf1b9a5b2f10d39afacc40c2576084f0e",
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
