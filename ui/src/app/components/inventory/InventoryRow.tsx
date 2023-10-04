import { useEffect, useState, ReactElement, useCallback } from "react";
import { useContracts } from "../../hooks/useContracts";
import { Button } from "../buttons/Button";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { Item } from "@/app/types";
import { GameData } from "../GameData";
import { getKeyFromValue } from "@/app/lib/utils";

interface InventoryRowProps {
  title: string;
  items: Item[];
  menuIndex: number;
  isActive: boolean;
  setActiveMenu: (value: number | undefined) => void;
  isSelected: boolean;
  setSelected: (value: number) => void;
  equippedItem: string | undefined;
  icon?: ReactElement;
  equipItems: string[];
  setEquipItems: (value: string[]) => void;
}

export const InventoryRow = ({
  title,
  items,
  menuIndex,
  isActive,
  setActiveMenu,
  isSelected,
  setSelected,
  equippedItem,
  icon,
  equipItems,
  setEquipItems,
}: InventoryRowProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);

  const gameData = new GameData();

  const handleEquipItems = (item: string) => {
    setEquipItems([...equipItems, getKeyFromValue(gameData.ITEMS, item) ?? ""]);
    if (gameContract) {
      const equipItemTx = {
        contractAddress: gameContract?.address,
        entrypoint: "equip",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
          equipItems.length,
          ...equipItems,
          // getKeyFromValue(gameData.ITEMS, item) ?? "",
        ],
        metadata: `Equipping ${item}!`,
      };
      addToCalls(equipItemTx);
    }
  };

  const unequippedItems = items?.filter((item) => item.item != equippedItem);

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowDown":
          setSelectedIndex((prev) => {
            const newIndex = Math.min(prev + 1, unequippedItems?.length - 1);
            return newIndex;
          });
          break;
        case "ArrowUp":
          setSelectedIndex((prev) => {
            const newIndex = Math.max(prev - 1, 0);
            return newIndex;
          });
          break;
        case "Enter":
          handleEquipItems(unequippedItems[selectedIndex]?.item ?? "");
          break;
        case "Escape":
          setActiveMenu(undefined);
          break;
      }
    },
    [selectedIndex, handleEquipItems, setActiveMenu, unequippedItems]
  );

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex, handleKeyDown]);

  return (
    <div className="flex flex-row w-full gap-3 sm:gap-1 align-center">
      <div className="sm:hidden">
        <Button
          className={`h-14 w-12 sm:w-full ${
            isSelected && !isActive ? "animate-pulse" : ""
          }`}
          variant={isSelected ? "default" : "ghost"}
          size={"sm"}
          onClick={() => {
            setSelected(menuIndex);
            setActiveMenu(menuIndex);
          }}
          disabled={!adventurer?.id}
        >
          <div className="flex flex-row gap-1 items-center">
            <div className="flex items-center justify-center w-8 h-8">
              {icon}
            </div>
            <p className="text-xl whitespace-nowrap hidden sm:block">{title}</p>
          </div>
        </Button>
      </div>
      <div className="hidden sm:block">
        <Button
          className={`h-14 w-12 sm:w-full ${
            isSelected && !isActive ? "animate-pulse" : ""
          }`}
          variant={isSelected ? "default" : "ghost"}
          size={"lg"}
          onClick={() => {
            setSelected(menuIndex);
            setActiveMenu(menuIndex);
          }}
          disabled={!adventurer?.id}
        >
          <div className="flex flex-row gap-1 items-center">
            <div className="flex items-center justify-center w-8 h-8">
              {icon}
            </div>
            <p className="text-xl whitespace-nowrap hidden sm:block">{title}</p>
          </div>
        </Button>
      </div>
    </div>
  );
};
