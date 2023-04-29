import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "http://survivor-indexer.bibliothecadao.xyz:5050";

export const contracts = {
  testnet: {
    adventurer:
      "0x0218aef38510a4d1cf523ca0cee301778139d90119a78a3a6e4874986a3ebf2b",
    lootMarketArcade:
      "0x07bdc1dca0de22eb0ffce91dd4995173a0285a1ae9f526a689298dfc3324decb",
    beast: "0x0487ae03df0c66407b1ccdb6d0b5c55b8fef7365f43c30dc554ceeb1b6d4b30c",
    lords_erc20_mintable:
      "0x076952f27f5c6afe3444aea88afa7b2da4caa4c738c1bf800e697c992442e97f",
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
