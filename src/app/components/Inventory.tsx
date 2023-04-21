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
import { padAddress, groupBySlot } from "../lib/utils";
import { InventoryRow } from "./InventoryRow";
// import { GameData } from "./GameData";

const Inventory: React.FC = () => {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const { addToCalls, calls } = useTransactionCart();
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
        setSelectedIndex((prev) => Math.min(prev + 1, items.length - 1));
        break;
      case "Enter":
        !items[selectedIndex].equippedAdventurerId
          ? handleAddEquipItem(items[selectedIndex].id)
          : null;
        break;
    }
  };

  const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return (
      <>
        {formatItem
          ? `${formatItem.item} [Rank ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp} XP]`
          : "Nothing"}
      </>
    );
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  const groupedItems = groupBySlot(items);

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
    <div className="flex flex-row bg-terminal-black border-2 border-terminal-green h-full p-8 gap-6">
      <div className="flex flex-col items-center my-auto">
        <div className="w-[250px] h-[250px] relative border-2 border-white my-auto">
          <Image
            src="/MIKE.png"
            alt="adventurer-image"
            fill={true}
            style={{ objectFit: "contain" }}
          />
        </div>
        <p className="text-2xl text-white mx-auto">
          {formatAdventurer.adventurer?.name}
        </p>
      </div>
      <div className="flex flex-col gap-7 text-[30px] mt-10">
        <p>WEAPONS</p>
        <p>HEAD</p>
        <p>CHEST</p>
        <p>FEET</p>
        <p>HANDS</p>
        <p>WAIST</p>
        <p>NECK</p>
        <p>RING</p>
      </div>
      <div className="flex flex-col gap-6">
        <div className="text-xl font-medium text-white">EQUIPPED</div>
        <div className="flex flex-col gap-12">
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.weaponId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.headId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.chestId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.feetId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.handsId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.waistId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.neckId
              )}
            />
          </p>
          <p className="text-terminal-green">
            <ItemDisplay
              item={items.find(
                (item: any) => item.id == formatAdventurer.adventurer?.ringId
              )}
            />
          </p>
        </div>
      </div>
      <div className="flex flex-col gap-6">
        <div className="text-xl font-medium text-white">OWNED</div>
        <div className="flex flex-col gap-7">
          <InventoryRow
            items={groupedItems["Weapon"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Head"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Chest"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Foot"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Hand"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Waist"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Neck"]}
            activeMenu={0}
            isActive={false}
          />
          <InventoryRow
            items={groupedItems["Ring"]}
            activeMenu={0}
            isActive={false}
          />
        </div>
      </div>
    </div>
  );
};

export default Inventory;
