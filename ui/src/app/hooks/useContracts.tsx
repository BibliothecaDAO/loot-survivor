import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x03fb428dcb56d42b9ae3e2687698b63c66b41f55d7528a4b7819dfe02c06653c",
    lootMarketArcade:
      "0x0333529dc1293ae28ab3c7b89b4edfd8f49a7eed94485beecda1cee070bf5fb7",
    beast: "0x057a1498976866ff1850957925ff70a9ee903f0cbe5b085e168de0304426c76d",
    lords_erc20_mintable:
      "0x03492ba6e57e8cb3c7776c505a1b2c1b8bc857076c28c888f3cc187918c95c60",
  },
  goerli: {
    adventurer:
      "0x04abf49f8e1706388049ee3bda370c8b9dcad9f90c2e9a740a3e28ca20ddac72",
    lootMarketArcade:
      "0x0020c2aaa6398d604b6d773e27551779578cdc825b61aec631c2bdd0570869b3",
    beast: "0x04b68a5f16f2ab3684db80fd61adebb44890874303367cdf9a9b5117ac0e2327",
    lords_erc20_mintable:
      "0x071d4f1882b8db3429c59181ae829cd180196c5a4e0d1c56d1e49f120ce12925",
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
