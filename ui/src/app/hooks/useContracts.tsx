import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    game: "0x00",
    lords_erc20_mintable:
      "0x067e87cea28bfd9314a1d3c41fb26a58ca1346ff0ea2452e59b9eeb2828692dc",
  },
  goerli: {
    game: "0x00",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
  },
};

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: gameContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == testnet_addr ||
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.game
        : contracts.goerli.game,
    abi: Adventurer,
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
    gameContract,
    lordsContract,
  };
};
