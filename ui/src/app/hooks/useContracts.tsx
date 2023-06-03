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
      "0x059daa60c4fbbb2866bbaf55b32916bd55d39243a2f97d78938fdfba79f1a4f2",
    lootMarketArcade:
      "0x051f4d360d69a19ff9cc00ebf733d0485e52e2880f0e1e506b041a4770418181",
    beast: "0x00d4941e7c42c06437cff11b2f50933d38b19ffd6c9a317bbddcc836ca83f113",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
  },
};

export const useContracts = () => {
  const { account } = useAccount();

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
