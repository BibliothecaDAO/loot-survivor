import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x024144ef19ad4c5767e5056fbdca9b6867e8b82d8d45768bbff0498fdedc6ac4",
    lootMarketArcade:
      "0x00c664109403c47238859a4e0c8d34424c06c41636fa2167a2528abc95c860f0",
    beast: "0x02badcca85581480702a9dded0c9fb004743e25246e9fd96fa970027575a339e",
    lords_erc20_mintable:
      "0x067e87cea28bfd9314a1d3c41fb26a58ca1346ff0ea2452e59b9eeb2828692dc",
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
  console.log(account);

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == testnet_addr ||
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.adventurer
        : contracts.goerli.adventurer,
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == testnet_addr ||
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.lootMarketArcade
        : contracts.goerli.lootMarketArcade,
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == testnet_addr ||
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.beast
        : contracts.goerli.beast,
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == testnet_addr ||
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
