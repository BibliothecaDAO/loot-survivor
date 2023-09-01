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
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const inventorySelected = useUIStore((state) => state.inventorySelected);
  const setInventorySelected = useUIStore(
    (state) => state.setInventorySelected
  );
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });
  const transactingItemIds = (transactions[0]?.metadata as Metadata)?.items;
  const equipItems = useUIStore((state) => state.equipItems);
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);

  const { data } = useQueriesStore();

  const items = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const handleEquipItems = (item: string) => {
    const newEquipItems = [
      ...equipItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setEquipItems(newEquipItems);
    if (gameContract && formatAddress) {
      const equipItemTx = {
        contractAddress: gameContract?.address,
        entrypoint: "equip",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
          newEquipItems.length.toString(),
          ...newEquipItems,
        ],
        metadata: `Equipping ${item}!`,
      };
      removeEntrypointFromCalls(equipItemTx.entrypoint);
      addToCalls(equipItemTx);
    }
  };

  const handleDropItems = (item: string) => {
    const newDropItems = [
      ...dropItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setDropItems(newDropItems);
    if (gameContract) {
      const dropItemsTx = {
        contractAddress: gameContract?.address,
        entrypoint: "drop_items",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
          newDropItems.length.toString(),
          ...newDropItems,
        ],
        metadata: `Dropping ${item}!`,
      };
      removeEntrypointFromCalls(dropItemsTx.entrypoint);
      addToCalls(dropItemsTx);
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
      <div className="hidden sm:block sm:w-1/2 lg:w-1/3">
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
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="weapon" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="chest" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="head" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="hand" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="waist" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="foot" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="neck" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
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
          icon={<LootIcon type="ring" size="w-4" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
        />
      </div>
      {adventurer?.id ? (
        <div className="w-5/6 sm:w-1/2">
          <div className="flex flex-col sm:gap-5">
            <span className="flex flex-row justify-between">
              <h4 className="m-0">{selected} Loot</h4>{" "}
              <span className="flex text-lg items-center sm:text-3xl">
                <BagIcon className="self-center w-4 h-4 fill-current" />{" "}
                {`${items.length}/${19}`}
              </span>
            </span>
            <div className="flex-row items-center gap-5 p-2 border border-terminal-green hidden sm:flex">
              <div className="w-10">
                <InfoIcon />
              </div>
              <p className="leading-5">
                Items of Tier 1 carry the highest prestige and quality, whereas
                items of Tier 5 offer the most basic value.
              </p>
            </div>
            <div className="flex flex-col overflow-y-auto h-[450px] sm:h-[360px] 2xl:h-full 2xl:overflow-y-hidden">
              {selectedItems.length ? (
                selectedItems.map((item: Item, index: number) => {
                  const itemId =
                    getKeyFromValue(gameData.ITEMS, item?.item ?? "") ?? "";
                  return (
                    <div className="w-full mb-1" key={index}>
                      <ItemDisplay
                        item={item}
                        inventory={true}
                        equip={() => {
                          setEquipItems([...equipItems, itemId]);
                          handleEquipItems(item.item ?? "");
                        }}
                        equipped={item.equipped}
                        disabled={
                          singleEquipExists(item.item ?? "") ||
                          item.equipped ||
                          checkTransacting(item.item ?? "") ||
                          equipItems.includes(itemId)
                        }
                        handleDrop={handleDropItems}
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
                  );
                })
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
