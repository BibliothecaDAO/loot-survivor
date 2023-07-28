import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";
import { contracts, mainnet_addr } from "../lib/constants";

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
