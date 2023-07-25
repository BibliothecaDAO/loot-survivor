import { useState, useEffect, useCallback } from "react";
import { useContracts } from "../hooks/useContracts";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
} from "@starknet-react/core";
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
import { InfoIcon, BagIcon } from "../components/icons/Icons";
import { Call, Item, Metadata } from "../types";
import { GameData } from "../components/GameData";
import useCustomQuery from "../hooks/useCustomQuery";
import { getAdventurerById } from "../hooks/graphql/queries";
import useUIStore from "../hooks/useUIStore";

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
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const inventorySelected = useUIStore((state) => state.inventorySelected);
  const setInventorySelected = useUIStore(
    (state) => state.setInventorySelected
  );
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });
  const transactingItemIds = (transactions[0]?.metadata as Metadata)?.items;

  const { data } = useQueriesStore();

  const items = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    txAccepted
  );

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
    return calls.some(
      (call: Call) =>
        call.entrypoint == "equip" &&
        Array.isArray(call.calldata) &&
        call.calldata[2] == getKeyFromValue(gameData.ITEMS, item)?.toString()
    );
  };

  const checkTransacting = (item: string) => {
    if (txData?.status == "RECEIVED" || txData?.status == "PENDING") {
      return transactingItemIds?.includes(item);
    } else {
      return false;
    }
  };

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowUp":
          setInventorySelected(Math.max((inventorySelected ?? 0) - 1, 0));
          break;
        case "ArrowDown":
          setInventorySelected(Math.min((inventorySelected ?? 0) + 1, 8 - 1));
          break;
        case "Enter":
          setActiveMenu(inventorySelected ?? 0);
          break;
      }
    },
    [setInventorySelected, setActiveMenu, inventorySelected]
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

  const groupedItems = groupBySlot(items);

  enum Menu {
    All = "All",
    Weapon = "Weapon",
    Chest = "Chest",
    Head = "Head",
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

  const selected = getValueByIndex(Menu, inventorySelected ?? 0);

  const selectedItems = groupedItems[selected || "Weapon"] || [];

  return (
    <div className="flex flex-row sm:gap-5">
      <div className="hidden sm:block sm:w-1/3">
        <Info adventurer={adventurer} />
      </div>
      <div className="flex flex-col w-1/6">
        <InventoryRow
          title={"All"}
          items={groupedItems["All"]}
          menuIndex={0}
          isActive={activeMenu == 0}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 0}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.weapon}
          icon={<LootIcon type="bag" />}
        />
        <InventoryRow
          title={"Weapon"}
          items={groupedItems["Weapon"]}
          menuIndex={1}
          isActive={activeMenu == 1}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 1}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.weapon}
          icon={<LootIcon type="weapon" />}
        />
        <InventoryRow
          title={"Chest Armor"}
          items={groupedItems["Chest"]}
          menuIndex={2}
          isActive={activeMenu == 2}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 2}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.chest}
          icon={<LootIcon type="chest" />}
        />
        <InventoryRow
          title={"Head Armor"}
          items={groupedItems["Head"]}
          menuIndex={3}
          isActive={activeMenu == 3}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 3}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.head}
          icon={<LootIcon type="head" />}
        />
        <InventoryRow
          title={"Hand Armor"}
          items={groupedItems["Hand"]}
          menuIndex={4}
          isActive={activeMenu == 4}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 4}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.hand}
          icon={<LootIcon type="hand" />}
        />
        <InventoryRow
          title={"Waist Armor"}
          items={groupedItems["Waist"]}
          menuIndex={5}
          isActive={activeMenu == 5}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 5}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.waist}
          icon={<LootIcon type="waist" />}
        />
        <InventoryRow
          title={"Foot Armor"}
          items={groupedItems["Foot"]}
          menuIndex={6}
          isActive={activeMenu == 6}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 6}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.foot}
          icon={<LootIcon type="foot" />}
        />
        <InventoryRow
          title={"Neck Jewelry"}
          items={groupedItems["Neck"]}
          menuIndex={7}
          isActive={activeMenu == 7}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 7}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.neck}
          icon={<LootIcon type="neck" />}
        />
        <InventoryRow
          title={"Ring Jewelry"}
          items={groupedItems["Ring"]}
          menuIndex={8}
          isActive={activeMenu == 8}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 8}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.ring}
          icon={<LootIcon type="ring" />}
        />
      </div>
      {adventurer?.id ? (
        <div className="w-5/6 sm:w-1/2">
          <div className="flex flex-col sm:gap-5">
            <h4 className="m-0">{selected} Loot</h4>
            <div className="flex-row items-center gap-5 p-2 border border-terminal-green hidden sm:flex">
              <div className="w-10">
                <InfoIcon />
              </div>
              <p className="leading-5">
                Items of Tier 1 carry the highest prestige and quality, whereas
                items of Tier 5 offer the most basic value.
              </p>
            </div>
            <div className="flex flex-col overflow-y-auto h-[450px] sm:h-[550px]">
              {selectedItems.length ? (
                selectedItems.map((item: Item, index: number) => (
                  <div className="w-full" key={index}>
                    <ItemDisplay
                      item={item}
                      inventory={true}
                      equip={() => handleAddEquipItem(item.item ?? "")}
                      equipped={item.equipped}
                      disabled={
                        singleEquipExists(item.item ?? "") ||
                        item.equipped ||
                        checkTransacting(item.item ?? "")
                      }
                    />
                    {/* <Button
                      onClick={() => handleAddEquipItem(item.item ?? "")}
                      disabled={
                        singleEquipExists(item.item ?? "") ||
                        item.equipped ||
                        checkTransacting(item.item ?? "")
                      }
                      loading={loading}
                    >
                      {item.equipped ? "Eqipped" : "Equip"}
                    </Button> */}
                  </div>
                ))
              ) : (
                <p className="sm:text-xl">You have no {selected} Loot</p>
              )}
            </div>
          </div>
        </div>
      ) : (
        <p className="text-xl text-center">Please Select an Adventurer</p>
      )}
    </div>
  );
}
