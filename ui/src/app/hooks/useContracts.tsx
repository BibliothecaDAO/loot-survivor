import { useContract, useAccount } from "@starknet-react/core";
import Game from "../abi/Game.json";
import Lords from "../abi/Lords.json";
import { contracts, mainnet_addr } from "../lib/constants";

const ethBalanceABIFragment = [
  {
    members: [
      {
        name: "low",
        offset: 0,
        type: "felt",
      },
      {
        name: "high",
        offset: 1,
        type: "felt",
      },
    ],
    name: "Uint256",
    size: 2,
    type: "struct",
  },
  {
    name: "balanceOf",
    type: "function",
    inputs: [
      {
        name: "account",
        type: "felt",
      },
    ],
    outputs: [
      {
        name: "balance",
        type: "Uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        name: "symbol",
        type: "felt",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        name: "decimals",
        type: "felt",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: gameContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == mainnet_addr ||
      (account as any)?.baseUrl == mainnet_addr
        ? contracts.mainnet.game
        : contracts.goerli.game,
    abi: Game,
  });
  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.provider?.baseUrl == mainnet_addr ||
      (account as any)?.baseUrl == mainnet_addr
        ? contracts.mainnet.lords
        : contracts.goerli.lords,
    abi: Lords,
  });

  const { contract: ethContract } = useContract({
    abi: ethBalanceABIFragment,
    address: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
  });

  return {
    gameContract,
    lordsContract,
    ethContract,
  };
};
