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
import { getItemsByAdventurer } from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import Image from "next/image";
import { groupBySlot } from "../lib/utils";
import { InventoryRow } from "./InventoryRow";
import Info from "./Info";
import { ItemDisplay } from "./ItemDisplay";
import { Button } from "./Button";
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
        calldata: [formatAdventurer?.adventurer?.id, "0", itemId, "0"],
        metadata: `Equipping ${itemId}!`,
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

  enum Menu {
    Weapon = "Weapon",
    Head = "Head",
    Chest = "Chest",
    Feet = "Foot",
    Hands = "Hand",
    Waist = "Waist",
    Neck = "Neck",
    Ring = "Ring",
  }

  function getValueByIndex(
    enumObject: object,
    index: number
  ): string | undefined {
    const values = Object.values(enumObject);
    return values[index];
  }

  const selected = getValueByIndex(Menu, selectedIndex);

  const selectedItemType = groupedItems[selected || "Weapon"] || [];

  function selectedIds(obj: any, keys: any) {
    const values = [];

    for (const key of keys) {
      if (obj.hasOwnProperty(key)) {
        values.push(obj[key]);
      }
    }

    return values;
  }

  const equipedItemIds = selectedIds(formatAdventurer.adventurer, [
    "weaponId",
    "headId",
    "chestId",
    "feetId",
    "handsId",
    "waistId",
    "neckId",
    "ringId",
  ]);

  console.log(groupedItems["Hand"]);

  const filteredItems = selectedItemType.filter(
    (item: any) => !equipedItemIds.includes(item.id)
  );

  return (
    <div className="flex flex-row space-x-4 overflow-hidden ">
      <div className="w-1/3">
        <Info adventurer={formatAdventurer.adventurer} />
      </div>
      <div className="flex flex-col">
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
      <div>
        <h4>Loot</h4>
        <div className="flex flex-col space-y-1">
          {filteredItems.length ? (
            filteredItems.map((item: any, index: number) => (
              <div className="flex">
                <ItemDisplay key={index} item={item} />
                <Button onClick={() => handleAddEquipItem(item.id)}>
                  equip
                </Button>
              </div>
            ))
          ) : (
            <div>You have no unequipped {selected} Loot</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Inventory;
