import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import {
  getItemsByAdventurer,
} from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import Image from "next/image";
import { groupBySlot } from "../lib/utils";
import { InventoryRow } from "./InventoryRow";
// import { GameData } from "./GameData";

const Inventory: React.FC = () => {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const { addToCalls } = useTransactionCart();
  const { adventurerContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { adventurer } = useAdventurer();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();

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
        setActiveMenu(selectedIndex);
        break;
    }
  };

  useEffect(() => {
    if (!activeMenu) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [activeMenu]);

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
    <div className="flex flex-row bg-terminal-black border-2 border-terminal-green h-[520px] p-8 gap-6 overflow-hidden">
      <div className="flex flex-col items-center">
        <div className="w-[250px] h-[250px] relative border-2 border-white m-2">
          <Image
            src="/MIKE.png"
            alt="adventurer-image"
            fill={true}
            style={{ objectFit: "contain" }}
          />
        </div>
        <p className="mx-auto text-2xl text-white">
          {formatAdventurer.adventurer?.name}
        </p>
      </div>
      <div className="flex flex-col gap-5">
        <InventoryRow
          title={"Weapon"}
          items={groupedItems["Weapon"]}
          menuIndex={0}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 0}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.weaponId}
        />
        <InventoryRow
          title={"Head Armour"}
          items={groupedItems["Head"]}
          menuIndex={1}
          isActive={activeMenu == 1}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 1}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.headId}
        />
        <InventoryRow
          title={"Chest Armour"}
          items={groupedItems["Chest"]}
          menuIndex={2}
          isActive={activeMenu == 2}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 2}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.chestId}
        />
        <InventoryRow
          title={"Feet Armour"}
          items={groupedItems["Foot"]}
          menuIndex={3}
          isActive={activeMenu == 3}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 3}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.feetId}
        />
        <InventoryRow
          title={"Hands Armour"}
          items={groupedItems["Hand"]}
          menuIndex={4}
          isActive={activeMenu == 4}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 4}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.handsId}
        />
        <InventoryRow
          title={"Waist Armour"}
          items={groupedItems["Waist"]}
          menuIndex={5}
          isActive={activeMenu == 5}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 5}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.waistId}
        />
        <InventoryRow
          title={"Neck Jewelry"}
          items={groupedItems["Neck"]}
          menuIndex={6}
          isActive={activeMenu == 6}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 6}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.neckId}
        />
        <InventoryRow
          title={"Ring Jewelry"}
          items={groupedItems["Ring"]}
          menuIndex={7}
          isActive={activeMenu == 7}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 7}
          setSelected={setSelectedIndex}
          equippedItemId={adventurer?.adventurer?.ringId}
        />
      </div>
    </div>
  );
};

export default Inventory;
