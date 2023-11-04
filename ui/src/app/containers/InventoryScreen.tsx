import { useState, useEffect, useCallback } from "react";
import { Contract } from "starknet";
import { useAccount, useWaitForTransaction } from "@starknet-react/core";
import { getKeyFromValue, groupBySlot } from "@/app/lib/utils";
import { InventoryRow } from "@/app/components/inventory/InventoryRow";
import Info from "@/app/components/adventurer/Info";
import { ItemDisplay } from "@/app/components/adventurer/ItemDisplay";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import LootIcon from "@/app/components/icons/LootIcon";
import { InfoIcon } from "@/app/components/icons/Icons";
import { Item, Metadata } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";
import useUIStore from "@/app/hooks/useUIStore";
import useTransactionManager from "@/app/hooks/useTransactionManager";

interface InventoryScreenProps {
  gameContract: Contract;
}

/**
 * @container
 * @description Provides the inventory screen for the adventurer.
 */
export default function InventoryScreen({
  gameContract,
}: InventoryScreenProps) {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const inventorySelected = useUIStore((state) => state.inventorySelected);
  const setInventorySelected = useUIStore(
    (state) => state.setInventorySelected
  );
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({
    hash: hashes ? hashes[0] : "0x0",
  });
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
        entrypoint: "drop",
        calldata: [
          adventurer?.id?.toString() ?? "",
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

  const checkTransacting = (item: string) => {
    if (txData?.status == "RECEIVED") {
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
    Waist = "Waist",
    Foot = "Foot",
    Hand = "Hand",
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
    <div className="flex flex-row sm:gap-5 h-full">
      <div className="hidden sm:block sm:w-1/2 lg:w-1/3">
        <Info adventurer={adventurer} gameContract={gameContract} />
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
          icon={<LootIcon type="bag" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
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
          icon={<LootIcon type="weapon" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
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
          icon={<LootIcon type="chest" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
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
          icon={<LootIcon type="head" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
        />
        <InventoryRow
          title={"Waist Armor"}
          items={groupedItems["Waist"]}
          menuIndex={4}
          isActive={activeMenu == 4}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 4}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.waist}
          icon={<LootIcon type="waist" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
        />
        <InventoryRow
          title={"Foot Armor"}
          items={groupedItems["Foot"]}
          menuIndex={5}
          isActive={activeMenu == 5}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 5}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.foot}
          icon={<LootIcon type="foot" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
        />
        <InventoryRow
          title={"Hand Armor"}
          items={groupedItems["Hand"]}
          menuIndex={6}
          isActive={activeMenu == 6}
          setActiveMenu={setActiveMenu}
          isSelected={inventorySelected == 6}
          setSelected={setInventorySelected}
          equippedItem={adventurer?.hand}
          icon={<LootIcon type="hand" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
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
          icon={<LootIcon type="neck" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
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
          icon={<LootIcon type="ring" size="w-6" />}
          equipItems={equipItems}
          setEquipItems={setEquipItems}
          gameContract={gameContract}
        />
      </div>
      {adventurer?.id ? (
        <div className="w-5/6 sm:w-1/2">
          <div className="flex flex-col sm:gap-5 h-full">
            <span className="flex flex-row justify-between">
              <h4 className="m-0">{selected} Loot</h4>{" "}
              <span className="flex flex-row gap-1 text-lg items-center sm:text-3xl">
                <LootIcon type="bag" size="w-5" />
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
            <div className="flex flex-col gap-1 overflow-y-auto h-[450px] table-scroll">
              {selectedItems.length ? (
                selectedItems.map((item: Item, index: number) => {
                  const itemId =
                    getKeyFromValue(gameData.ITEMS, item?.item ?? "") ?? "";
                  return (
                    <ItemDisplay
                      item={item}
                      inventory={true}
                      equip={() => {
                        setEquipItems([...equipItems, itemId]);
                        handleEquipItems(item.item ?? "");
                      }}
                      equipped={item.equipped}
                      disabled={
                        item.equipped ||
                        checkTransacting(item.item ?? "") ||
                        equipItems.includes(itemId)
                      }
                      handleDrop={handleDropItems}
                      gameContract={gameContract}
                      key={index}
                    />
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
