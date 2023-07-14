import { useState, useEffect, useCallback } from "react";
import { useContracts } from "../hooks/useContracts";
import { useAccount } from "@starknet-react/core";
import { getKeyFromValue, groupBySlot } from "../lib/utils";
import { InventoryRow } from "../components/inventory/InventoryRow";
import Info from "../components/adventurer/Info";
import { ItemDisplay } from "../components/adventurer/ItemDisplay";
import { Button } from "../components/buttons/Button";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import useLoadingStore from "../hooks/useLoadingStore";
import LootIcon from "../components/icons/LootIcon";
import { InfoIcon } from "../components/icons/Icons";
import { Call, Item } from "../types";
import { GameData } from "../components/GameData";

/**
 * @container
 * @description Provides the inventory screen for the adventurer.
 */
export default function InventoryScreen() {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  const { data } = useQueriesStore();

  const items = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  // const items: any[] = [];

  const handleAddEquipItem = (item: string) => {
    if (gameContract && formatAddress) {
      const equipItemTx = {
        contractAddress: gameContract?.address,
        entrypoint: "equip",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
          getKeyFromValue(gameData.ITEMS, item) ?? "",
        ],
        metadata: `Equipping ${item}!`,
      };
      addToCalls(equipItemTx);
    }
  };

  const gameData = new GameData();

  const singleEquipExists = (item: string) => {
    console.log(getKeyFromValue(gameData.ITEMS, item)?.toString());
    return calls.some(
      (call: Call) =>
        call.entrypoint == "equip" &&
        Array.isArray(call.calldata) &&
        call.calldata[2] == getKeyFromValue(gameData.ITEMS, item)?.toString()
    );
  };

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
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
    },
    [setSelectedIndex, setActiveMenu, selectedIndex]
  );

  useEffect(() => {
    if (activeMenu === undefined) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [activeMenu, handleKeyDown]);

  const unequippedItems = items.filter((item: Item) => !item.equipped);

  const groupedItems = groupBySlot(unequippedItems);

  enum Menu {
    Weapon = "Weapon",
    Head = "Head",
    Chest = "Chest",
    Hand = "Hand",
    Waist = "Waist",
    Foot = "Foot",
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

  const selectedItems = groupedItems[selected || "Weapon"] || [];

  return (
    <div className="flex flex-row gap-5 sm:gap-5 sm:space-x-4 overflow-hidden flex-wrap">
      <div className="hidden sm:block sm:w-1/3">
        <Info adventurer={adventurer} />
      </div>
      <div className="flex flex-col gap-5 sm:gap-0">
        <InventoryRow
          title={"Weapon"}
          items={groupedItems["Weapon"]}
          menuIndex={0}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 0}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.weapon}
          icon={<LootIcon type="weapon" />}
        />
        <InventoryRow
          title={"Head Armour"}
          items={groupedItems["Head"]}
          menuIndex={1}
          isActive={activeMenu == 1}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 1}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.head}
          icon={<LootIcon type="head" />}
        />
        <InventoryRow
          title={"Chest Armour"}
          items={groupedItems["Chest"]}
          menuIndex={2}
          isActive={activeMenu == 2}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 2}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.chest}
          icon={<LootIcon type="chest" />}
        />
        <InventoryRow
          title={"Hands Armour"}
          items={groupedItems["Hand"]}
          menuIndex={3}
          isActive={activeMenu == 3}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 3}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.hand}
          icon={<LootIcon type="hand" />}
        />
        <InventoryRow
          title={"Waist Armour"}
          items={groupedItems["Waist"]}
          menuIndex={4}
          isActive={activeMenu == 4}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 4}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.waist}
          icon={<LootIcon type="waist" />}
        />
        <InventoryRow
          title={"Feet Armour"}
          items={groupedItems["Foot"]}
          menuIndex={5}
          isActive={activeMenu == 5}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 5}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.foot}
          icon={<LootIcon type="foot" />}
        />
        <InventoryRow
          title={"Neck Jewelry"}
          items={groupedItems["Neck"]}
          menuIndex={6}
          isActive={activeMenu == 6}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 6}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.neck}
          icon={<LootIcon type="neck" />}
        />
        <InventoryRow
          title={"Ring Jewelry"}
          items={groupedItems["Ring"]}
          menuIndex={7}
          isActive={activeMenu == 7}
          setActiveMenu={setActiveMenu}
          isSelected={selectedIndex == 7}
          setSelected={setSelectedIndex}
          equippedItem={adventurer?.ring}
          icon={<LootIcon type="ring" />}
        />
      </div>
      <div className="w-2/3 sm:w-1/3">
        <h4>Loot</h4>
        <div className="flex flex-col gap-5">
          <div className="flex-row items-center gap-5 p-2 border border-terminal-green hidden sm:flex">
            <div className="w-10">
              <InfoIcon />
            </div>
            <p className="leading-5">
              Items of Tier 1 carry the highest prestige and quality, whereas
              items of Tier 5 offer the most basic value.
            </p>
          </div>
          <div className="flex flex-col space-y-1">
            {selectedItems.length ? (
              selectedItems.map((item: any, index: number) => (
                <div
                  className="flex flex-row gap-2 w-full items-center justify-between"
                  key={item.id}
                >
                  <div className="w-full">
                    <ItemDisplay item={item} />
                  </div>
                  <Button
                    onClick={() => handleAddEquipItem(item.item)}
                    disabled={singleEquipExists(item.item)}
                    loading={loading}
                  >
                    equip
                  </Button>
                </div>
              ))
            ) : (
              <p className="sm:text-xl">
                You have no unequipped {selected} Loot
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
