import { useContract } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";

export const useContracts = () => {
  const { contract: AdventurerContract } = useContract({
    address:
      "0x047ce016a470b9fb3fd212ac0ce8e7cf035919a715e3381cfff9624eec1a3815",
    abi: Adventurer,
  });

  const { contract: LootMarketArcadeContract } = useContract({
    address:
      "0x01b73f18ffe0364d5634ddebdd6a428110a183861e4bf962b7e6f69bb9ddc1e5",
    abi: LootMarketArcade,
  });

  const { contract: BeastContract } = useContract({
    address:
      "0x0372dc195187c789a4f97487911fb3db895d180b2fc53bfa69f85f933e8424e6",
    abi: Beast,
  });

  return {
    AdventurerContract,
    LootMarketArcadeContract,
    BeastContract,
  };
};
