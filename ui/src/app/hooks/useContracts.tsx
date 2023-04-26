import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x07a6771c44602b93e8375610f886cefde0e3752073a5761b0fe2566281debf8e"
        : "0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248",
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x04fd9fd16370c0dd2c562cb7aa2d6b973142da85c0cfb740ea69841009e98380"
        : "0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f",
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x03b2879fae55706b2412c7798570877b0e42712f7010910bb7c92912b0c6c7f3"
        : "0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1",
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x00d150f39c3e69444d7e9f54ce8fa735807b2438c5e510c255187b5f9c23ff05"
        : "0x023b86be0b3da5c2fdbd80d1d57f1b54391588ba338acecdd014a208d47ba9ca",
    abi: Lords_ERC20_Mintable,
  });

  return {
    adventurerContract,
    lootMarketArcadeContract,
    beastContract,
    lordsContract,
  };
};
