import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const mainnet_addr = "https://alpha.starknet.io/";

export const contracts = {
  mainnet: {
    game: "0x0",
    lords_erc20_mintable:
      "0x067e87cea28bfd9314a1d3c41fb26a58ca1346ff0ea2452e59b9eeb2828692dc",
  },
  goerli: {
    game: "0x00f56b3b8ecd560f6160611c1756cde79bb0328a78d5190b074121c7d1e2639d",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
  },
};

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: gameContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == mainnet_addr ||
      (account as any)?.baseUrl == mainnet_addr
        ? contracts.mainnet.game
        : contracts.goerli.game,
    abi: Adventurer,
  });
  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == mainnet_addr ||
      (account as any)?.baseUrl == mainnet_addr
        ? contracts.mainnet.lords_erc20_mintable
        : contracts.goerli.lords_erc20_mintable,
    abi: Lords_ERC20_Mintable,
  });

  return {
    gameContract,
    lordsContract,
  };
};
