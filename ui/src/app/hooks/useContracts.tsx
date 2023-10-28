import { useContract } from "@starknet-react/core";
import Game from "@/app/abi/Game.json";
import Lords from "@/app/abi/Lords.json";
import Beasts from "@/app/abi/Beasts.json";
import GoldenToken from "@/app/abi/GoldenToken.json";

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
  const { contract: gameContract } = useContract({
    address: process.env.NEXT_PUBLIC_GAME_ADDRESS,
    abi: Game,
  });
  const { contract: lordsContract } = useContract({
    address: process.env.NEXT_PUBLIC_LORDS_ADDRESS,
    abi: Lords,
  });

  const { contract: ethContract } = useContract({
    address: process.env.NEXT_PUBLIC_ETH_ADDRESS,
    abi: ethBalanceABIFragment,
  });

  const { contract: beastsContract } = useContract({
    address: process.env.NEXT_PUBLIC_BEASTS_ADDRESS,
    abi: Beasts,
  });

  const { contract: goldenToken } = useContract({
    address: process.env.NEXT_PUBLIC_GOLDEN_TOKEN_ADDRESS,
    abi: GoldenToken,
  });

  return {
    gameContract,
    lordsContract,
    ethContract,
    beastsContract,
    goldenToken,
  };
};
