import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "http://survivor-indexer.bibliothecadao.xyz:5050";

export const contracts = {
  testnet: {
    adventurer:
      "0x06e948393d1923fa6a2d098f64a6bbc1f5b3c691fbc195db7356174635badb7e",
    lootMarketArcade:
      "0x021ea287f5e8f8f5cba96182c3d497b9b66038b9858b89171f671e383a9fd9d7",
    beast: "0x009c5e78ebba0180bca7a7ffac236432ca72ebdb556d52987677d0c3878dacca",
    lords_erc20_mintable:
      "0x028fe19e538bbdd6326b9450812e512dc8c0918296edb930c50dec4c8da6aaf7",
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
