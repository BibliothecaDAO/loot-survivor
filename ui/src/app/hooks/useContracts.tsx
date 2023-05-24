import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x013cfe04c070fdc37379084ef560b76ef72ebbfd5d9d199e0ac1e2b2184a13c5",
    lootMarketArcade:
      "0x031288084d9f15dc446f82db2c2eb32196aafea8d74244210750400035a49406",
    beast: "0x05bc7c27a0bf8a8cfe3f0316752082225a9dbce24f9bfe7f5c91db9d9eef6ab4",
    lords_erc20_mintable:
      "0x04e46fcf274b18db304bd16ae8c33af5876eb2b8a2fab35c3b7c8e7822cbd0fd",
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
