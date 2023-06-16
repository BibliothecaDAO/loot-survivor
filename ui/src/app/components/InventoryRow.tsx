import { useEffect, useState, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { NullAdventurer } from "../types";
import { Button } from "./Button";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import { useMediaQuery } from "react-responsive";

interface InventoryRowProps {
  title: string;
  items: any[];
  menuIndex: number;
  isActive: boolean;
  setActiveMenu: (value: any) => void;
  isSelected: boolean;
  setSelected: (value: any) => void;
  equippedItemId: number | undefined;
  icon?: any;
}

export const InventoryRow = ({
  title,
  items,
  menuIndex,
  isActive,
  setActiveMenu,
  isSelected,
  setSelected,
  equippedItemId,
  icon,
}: InventoryRowProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const { adventurerContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);

  const handleAddEquipItem = (itemId: any) => {
    if (adventurerContract) {
      const equipItem = {
        contractAddress: adventurerContract?.address,
        entrypoint: "equip_item",
        calldata: [adventurer?.id, "0", itemId, "0"],
        metadata: `Equipping ${itemId}!`,
      };
      addToCalls(equipItem);
    }
  };

  const unequippedItems = items?.filter((item) => item.id != equippedItemId);

  const handleKeyDown = (event: KeyboardEvent) => {
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
        handleAddEquipItem(unequippedItems[selectedIndex]?.id);
        break;
      case "Escape":
        setActiveMenu(undefined);
        break;
    }
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <>
      <div className="flex flex-row w-full gap-3 align-center">
        <Button
          className={isSelected && !isActive ? "animate-pulse" : ""}
          variant={isSelected ? "default" : "ghost"}
          size={isMobileDevice ? "sm" : "lg"}
          onClick={() => {
            setSelected(menuIndex);
            setActiveMenu(menuIndex);
          }}
        >
          {icon && (
            <div className="flex items-center justify-center w-10 h-10 sm:hidden">
              {icon}
            </div>
          )}
          <p className="w-40 text-xl whitespace-nowrap hidden sm:block">
            {title}
          </p>
        </Button>
      </div>
    </>
  );
};
