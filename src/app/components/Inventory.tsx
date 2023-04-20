import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { Button } from "./Button";
import { useQuery } from "@apollo/client";
import {
  getItemsByAdventurer,
  getItemsByOwner,
  getAdventurersByOwner,
} from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import Image from "next/image";
import { padAddress } from "../lib/utils";
// import { GameData } from "./GameData";

const Inventory: React.FC = () => {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const { writeAsync, addToCalls, calls } = useTransactionCart();
  const { adventurerContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { hashes, addTransaction } = useTransactionManager();
  const { adventurer } = useAdventurer();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const transactions = useTransactions({ hashes });

  // const gameData = new GameData();
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const {
    loading: itemsByAdventurerLoading,
    error: itemsByAdventurerError,
    data: itemsByAdventurerData,
    refetch: itemsByAdventurerRefetch,
  } = useQuery(getItemsByAdventurer, {
    variables: {
      adventurer: formatAdventurer.adventurer?.id,
    },
    pollInterval: 5000,
  });

  const items = itemsByAdventurerData ? itemsByAdventurerData.items : [];

  console.log(items);

  const handleAddEquipItem = (itemId: any) => {
    if (adventurerContract && formatAddress) {
      const equipItem = {
        contractAddress: adventurerContract?.address,
        selector: "equip_item",
        calldata: [formatAdventurer.adventurer?.id, itemId],
      };
      addToCalls(equipItem);
    }
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowUp":
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "ArrowDown":
        setSelectedIndex((prev) => Math.min(prev + 1, testItems.length - 1));
        break;
      case "Enter":
        !testItems[selectedIndex].equippedAdventurerId
          ? handleAddEquipItem(testItems[selectedIndex].id)
          : null;
        break;
    }
  };

  const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return (
      <>
        {formatItem
          ? `${formatItem.item} [Rank ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp}XP]`
          : "Nothing"}
      </>
    );
  };

  const testItems = [
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 143,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 144,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 145,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 146,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 147,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 148,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 149,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 150,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
    {
      bag: null,
      bidder: null,
      claimedTime: null,
      createdBlock: 1681911407,
      equippedAdventurerId: 41,
      expiry: null,
      greatness: 1,
      id: 151,
      item: "Club",
      lastUpdated: "2023-04-19T13:36:47",
      marketId: null,
      material: "Oak Hardwood",
      owner:
        "0x07642a1c8d575b0c0f9a7ad7cceb5517c02f36e5f3b36b25429cc7c99383ed0a",
      ownerAdventurerId: 41,
      prefix1: null,
      prefix2: null,
      price: null,
      rank: 5,
      slot: "Weapon",
      status: null,
      suffix: null,
      type: "Bludgeon Weapon",
      xp: 0,
      __typename: "Item",
    },
  ];

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  // useEffect(() => {
  //   const button = buttonRefs.current[selectedIndex];
  //   if (button) {
  //     button.scrollIntoView({
  //       behavior: "smooth",
  //       block: "nearest",
  //     });
  //   }
  // }, [selectedIndex]);

  return (
    <div className="flex flex-row bg-terminal-black border-2 border-terminal-green h-full p-10 gap-10">
      <div className="w-[250px] h-[250px] relative border-2 border-white my-auto">
        <Image
          src="/MIKE.png"
          alt="adventurer-image"
          fill={true}
          style={{ objectFit: "contain" }}
        />
      </div>
      <div className="flex flex-col gap-10">
        <div className="text-xl font-medium text-white">EQUIPPED</div>
        <p className="text-terminal-green">
          WEAPON -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.weaponId
            )}
          />
        </p>
        <p className="text-terminal-green">
          HEAD -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.headId
            )}
          />
        </p>
        <p className="text-terminal-green">
          CHEST -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.chestId
            )}
          />
        </p>
        <p className="text-terminal-green">
          FOOT -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.feetId
            )}
          />
        </p>
        <p className="text-terminal-green">
          HAND -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.handsId
            )}
          />
        </p>
        <p className="text-terminal-green">
          WAIST -{" "}
          <ItemDisplay
            item={items.find(
              (item: any) => item.id == formatAdventurer.adventurer?.waistId
            )}
          />
        </p>
      </div>
      <div className="flex flex-col gap-10">
        <div className="text-xl font-medium text-white">OWNED</div>
        <div className="flex flex-col gap-5 h-[400px] w-[600px] overflow-auto">
          {testItems.map((item: any, index: number) => (
            <div key={index} className="flex flex-row items-center gap-5">
              <ItemDisplay item={item} />
              <Button
                key={index}
                ref={(ref) => (buttonRefs.current[index] = ref)}
                className={
                  selectedIndex === index
                    ? item.equippedAdventurerId
                      ? "animate-pulse bg-white"
                      : "animate-pulse"
                    : ""
                }
                variant={selectedIndex === index ? "subtle" : "outline"}
                onClick={() => {
                  !testItems[selectedIndex].equippedAdventurerId
                    ? handleAddEquipItem(testItems[selectedIndex].id)
                    : null;
                }}
              >
                {item.equippedAdventurerId ? "Equipped" : "Equip"}
              </Button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Inventory;
