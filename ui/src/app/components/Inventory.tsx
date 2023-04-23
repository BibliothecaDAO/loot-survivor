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
        setSelectedIndex((prev) => Math.min(prev + 1, 8 - 1));
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
    <div className="flex flex-row bg-terminal-black border-2 border-terminal-green h-[520px] p-8 gap-6">
      <div className="flex flex-col items-center">
        <div className="w-[250px] h-[250px] relative border-2 border-white m-2">
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
      <div className="flex flex-col gap-8">
        <InventoryRow
          title={"Weapon"}
          items={groupedItems["Weapon"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 0}
          equippedItemId={adventurer?.adventurer?.weaponId}
        />
        <InventoryRow
          title={"Head Armour"}
          items={groupedItems["Head"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 1}
          equippedItemId={adventurer?.adventurer?.headId}
        />
        <InventoryRow
          title={"Chest Armour"}
          items={groupedItems["Chest"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 2}
          equippedItemId={adventurer?.adventurer?.chestId}
        />
        <InventoryRow
          title={"Feet Armour"}
          items={groupedItems["Foot"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 3}
          equippedItemId={adventurer?.adventurer?.feetId}
        />
        <InventoryRow
          title={"Hands Armour"}
          items={groupedItems["Hand"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 4}
          equippedItemId={adventurer?.adventurer?.handsId}
        />
        <InventoryRow
          title={"Waist Armour"}
          items={groupedItems["Waist"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 5}
          equippedItemId={adventurer?.adventurer?.waistId}
        />
        <InventoryRow
          title={"Neck Jewelry"}
          items={groupedItems["Neck"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 6}
          equippedItemId={adventurer?.adventurer?.neckId}
        />
        <InventoryRow
          title={"Ring Jewelry"}
          items={groupedItems["Ring"]}
          activeMenu={selectedIndex}
          isActive={selectedIndex == 7}
          equippedItemId={adventurer?.adventurer?.ringId}
        />
      </div>
    </div>
  );
};

export default Inventory;
