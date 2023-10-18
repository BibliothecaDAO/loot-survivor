import { useContract } from "@starknet-react/core";
import Game from "../abi/Game.json";
import Lords from "../abi/Lords.json";
import Beasts from "../abi/Beasts.json";
import GoldenToken from "../abi/GoldenToken.json";
import { getContracts } from "../lib/constants";

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
  const contracts = getContracts();

  const { contract: gameContract } = useContract({
    address: contracts?.game,
    abi: Game,
  });
  const { contract: lordsContract } = useContract({
    address: contracts?.lords,
    abi: Lords,
  });

  const { contract: ethContract } = useContract({
    address: contracts?.eth,
    abi: ethBalanceABIFragment,
  });

  const { contract: beastsContract } = useContract({
    address: contracts?.beasts,
    abi: Beasts,
  });

  const { contract: goldenToken } = useContract({
    address: contracts?.goldenToken,
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
