import { useCallback, useEffect, useState } from "react";
import { Button } from "@/app/components/buttons/Button";
import { getItemData, getItemPrice, getKeyFromValue } from "@/app/lib/utils";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import LootIcon from "@/app/components/icons/LootIcon";
import { Item, ItemPurchase, UpgradeStats, NullAdventurer } from "@/app/types";
import { CoinIcon } from "@/app/components/icons/Icons";
import EfficacyDisplay from "@/app/components/icons/EfficacyIcon";
import { GameData } from "@/app/lib/data/GameData";

interface MarketplaceRowProps {
  item: Item;
  index: number;
  activeMenu: number | null;
  setActiveMenu: (value: number | null) => void;
  calculatedNewGold: number;
  ownedItems: Item[];
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    purchases?: ItemPurchase[]
  ) => void;
  totalCharisma: number;
  dropItems: string[];
}

const MarketplaceRow = ({
  item,
  index,
  activeMenu,
  setActiveMenu,
  calculatedNewGold,
  ownedItems,
  purchaseItems,
  setPurchaseItems,
  upgradeHandler,
  totalCharisma,
  dropItems,
}: MarketplaceRowProps) => {
  const [selectedButton, setSelectedButton] = useState<number>(0);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const gameData = new GameData();

  const singlePurchaseExists = (item: string) => {
    return purchaseItems.some(
      (purchasingItem: ItemPurchase) => purchasingItem.item == item
    );
  };

  const { tier, type, slot } = getItemData(item.item ?? "");
  const itemPrice = getItemPrice(tier, totalCharisma);
  const enoughGold = calculatedNewGold >= itemPrice;

  const checkOwned = (item: string) => {
    return ownedItems.some((ownedItem) => ownedItem.item == item);
  };

  const checkPurchased = (item: string) => {
    return purchaseItems.some(
      (purchaseItem) =>
        purchaseItem.item == getKeyFromValue(gameData.ITEMS, item)
    );
  };

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowDown":
          setSelectedButton((prev) => {
            const newIndex = Math.min(prev + 1, 1);
            return newIndex;
          });
          break;
        case "ArrowUp":
          setSelectedButton((prev) => {
            const newIndex = Math.max(prev - 1, 0);
            return newIndex;
          });
          break;
        case "Enter":
          setActiveMenu(0);
          break;
        case "Escape":
          setActiveMenu(0);
          break;
      }
    },
    [selectedButton, setActiveMenu]
  );

  const isActive = activeMenu == index;

  const equippedItems = ownedItems.filter((obj) => obj.equipped).length;
  const baggedItems = ownedItems.filter((obj) => !obj.equipped).length;

  // Check whether an equipped slot is free, if it is free then even if the bag is full the slot can be bought and equipped.
  const formatAdventurer = adventurer ?? NullAdventurer;
  const equppedItem = formatAdventurer[slot.toLowerCase()];
  const emptySlot = equppedItem === null;

  const purchaseNoEquipItems = purchaseItems.filter(
    (item) => item.equip === "0"
  ).length;
  const purchaseEquipItems = purchaseItems.filter(
    (item) => item.equip === "1"
  ).length;

  const equipFull = equippedItems + purchaseEquipItems === 8;
  const bagFull = baggedItems + purchaseNoEquipItems === 15;

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [isActive, handleKeyDown]);

  return (
    <tr
      className={
        "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black w-full h-12 sm:h-full"
      }
    >
      <td className="text-center">{item.item}</td>
      <td className="text-center">{tier}</td>
      <td className="text-center">
        <div className="sm:hidden flex justify-center items-center">
          <LootIcon size={"w-5"} type={slot} />
        </div>
        <div className="hidden sm:flex justify-center items-center">
          <LootIcon size={"w-5"} type={slot} />
        </div>
      </td>
      <td className="text-center">
        <div className="flex flex-row items-center justify-center gap-2">
          <p className="hidden sm:block">{type}</p>
          <EfficacyDisplay size="w-5" className="h-5 sm:w-8" type={type} />
        </div>
      </td>
      <td className="text-center">
        <div className="flex flex-row items-center justify-center">
          <CoinIcon className="w-4 h-4 sm:w-8 sm:h-8 fill-current text-terminal-yellow" />
          <p className="text-terminal-yellow">
            {getItemPrice(tier, totalCharisma)}
          </p>
        </div>
      </td>

      <td className="w-20 sm:w-32 text-center">
        {activeMenu === index ? (
          <div className="hidden sm:flex flex-row items-center justify-center gap-2">
            <Button
              className="w-10"
              variant={"contrast"}
              onClick={() => {
                const newPurchases = [
                  ...purchaseItems,
                  {
                    item:
                      getKeyFromValue(gameData.ITEMS, item?.item ?? "") ?? "0",
                    equip: "1",
                  },
                ];
                setPurchaseItems(newPurchases);
                upgradeHandler(undefined, undefined, newPurchases);
                setActiveMenu(null);
              }}
            >
              Equip
            </Button>
            <Button
              className="w-10"
              variant={"contrast"}
              onClick={() => {
                const newPurchases = [
                  ...purchaseItems,
                  {
                    item:
                      getKeyFromValue(gameData.ITEMS, item?.item ?? "") ?? "0",
                    equip: "0",
                  },
                ];
                setPurchaseItems(newPurchases);
                upgradeHandler(undefined, undefined, newPurchases);
                setActiveMenu(null);
              }}
              disabled={bagFull}
            >
              Bag
            </Button>

            <Button
              className="text-8xl"
              variant={"ghost"}
              onClick={() => setActiveMenu(null)}
            >
              X
            </Button>
          </div>
        ) : (
          <Button
            onClick={() => {
              setActiveMenu(index);
            }}
            className="h-10 w-16 sm:h-auto sm:w-auto"
            disabled={
              itemPrice > (adventurer?.gold ?? 0) ||
              !enoughGold ||
              singlePurchaseExists(item.item ?? "") ||
              item.owner ||
              checkOwned(item.item ?? "") ||
              checkPurchased(item.item ?? "") ||
              (equipFull && bagFull) ||
              (bagFull && !emptySlot)
            }
          >
            {!enoughGold || itemPrice > (adventurer?.gold ?? 0)
              ? "Not Enough Gold"
              : singlePurchaseExists(item.item ?? "") ||
                checkPurchased(item.item ?? "")
              ? "In Cart"
              : checkOwned(item.item ?? "")
              ? "Owned"
              : (equipFull && bagFull) || (bagFull && !emptySlot)
              ? "Inventory Full"
              : "Purchase"}
          </Button>
        )}
      </td>
    </tr>
  );
};

export default MarketplaceRow;
