import { useEffect, useState, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { Button } from "./Button";

interface InventoryRowProps {
  title: string;
  items: any[];
  activeMenu: number;
  isActive: boolean;
  equippedItemId: number | undefined;
}

export const InventoryRow = ({
  title,
  items,
  activeMenu,
  isActive,
  equippedItemId,
}: InventoryRowProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const { adventurerContract } = useContracts();
  const { adventurer } = useAdventurer();
  const { addToCalls } = useTransactionCart();
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  const handleAddEquipItem = (itemId: any) => {
    if (adventurerContract) {
      const equipItem = {
        contractAddress: adventurerContract?.address,
        selector: "equip_item",
        calldata: [formatAdventurer?.id, itemId],
      };
      addToCalls(equipItem);
    }
  };

  const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return (
      <p className="w-full">
        {formatItem
          ? `${formatItem.item} [Rank ${formatItem.rank}, Greatness ${formatItem.greatness}, ${formatItem.xp} XP]`
          : "Nothing"}
      </p>
    );
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowDown":
        setSelectedIndex((prev) => {
          const newIndex = Math.min(prev + 1, items?.length - 1);
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
        !items[selectedIndex].equippedAdventurerId
          ? handleAddEquipItem(items[selectedIndex].id)
          : null;
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
  return (
    <div className="flex flex-row gap-10 w-full">
      <p className="text-2xl w-60">{title}</p>
      <ItemDisplay
        item={items?.find((item: any) => item.id == equippedItemId)}
      />
      <div className="flex flex-row gap-5 w-full overflow-auto">
        {items?.map((item: any, index: number) => (
          <>
            {item.id != equippedItemId ? (
              <div key={index} className="flex flex-col items-center">
                <ItemDisplay item={item} />
                <Button
                  key={index}
                  ref={(ref) => (buttonRefs.current[index] = ref)}
                  className={
                    selectedIndex === index && isActive
                      ? item.equippedAdventurerId
                        ? "animate-pulse bg-white"
                        : "animate-pulse"
                      : "h-[20px]"
                  }
                  variant={selectedIndex === index ? "subtle" : "outline"}
                  size={"xs"}
                  onClick={() => {
                    !items[selectedIndex].equippedAdventurerId
                      ? handleAddEquipItem(items[selectedIndex].id)
                      : null;
                  }}
                >
                  Equip
                </Button>
              </div>
            ) : null}
          </>
        ))}
      </div>
    </div>
  );
};
