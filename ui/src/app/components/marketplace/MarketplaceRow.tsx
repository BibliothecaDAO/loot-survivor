import { useCallback, useEffect, useState } from "react";
import { Button } from "../buttons/Button";
import { getItemData, getItemPrice, getKeyFromValue } from "../../lib/utils";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import LootIcon from "../icons/LootIcon";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { Metadata, Item, ItemPurchase, UpgradeStats } from "../../types";
import { CoinIcon } from "../icons/Icons";
import EfficacyDisplay from "../icons/EfficacyIcon";
import { GameData } from "../GameData";

interface MarketplaceRowProps {
  item: Item;
  index: number;
  selectedIndex: number;
  activeMenu: number | null;
  setActiveMenu: (value: number | null) => void;
  calculatedNewGold: number;
  ownedItems: Item[];
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    purchases?: any[]
  ) => void;
  totalCharisma: number;
}

const MarketplaceRow = ({
  item,
  index,
  selectedIndex,
  activeMenu,
  setActiveMenu,
  calculatedNewGold,
  ownedItems,
  purchaseItems,
  setPurchaseItems,
  upgradeHandler,
  totalCharisma,
}: MarketplaceRowProps) => {
  const [selectedButton, setSelectedButton] = useState<number>(0);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });

  const transactingMarketIds = (transactions[0]?.metadata as Metadata)?.items;

  const gameData = new GameData();

  const singlePurchaseExists = (item: string) => {
    return purchaseItems.some(
      (purchasingItem: ItemPurchase) => purchasingItem.item == item
    );
  };

  const { tier, type, slot } = getItemData(item.item ?? "");
  const itemPrice = getItemPrice(tier, totalCharisma);
  const enoughGold = calculatedNewGold >= itemPrice;

  const checkTransacting = (item: string) => {
    if (txData?.status == "RECEIVED") {
      return transactingMarketIds?.includes(item);
    } else {
      return false;
    }
  };

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
        "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black w-full" +
        (selectedIndex === index + 1 ? " bg-terminal-black" : "")
      }
    >
      <td className="text-center">{item.item}</td>
      <td className="text-center">{tier}</td>
      <td className="text-center">
        <div className="sm:hidden flex justify-center items-center">
          <LootIcon size={"w-4"} type={slot} />
        </div>
        <div className="hidden sm:flex justify-center items-center">
          <LootIcon size={"w-5"} type={slot} />
        </div>
      </td>
      <td className="text-center">
        <div className="flex flex-row items-center justify-center gap-2">
          <p className="hidden sm:block">{type}</p>
          <EfficacyDisplay className="sm:w-8" type={type} />
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
            <p>Equip?</p>
            <div className="flex flex-col">
              <Button
                size={"xs"}
                variant={"ghost"}
                onClick={() => {
                  const newPurchases = [
                    ...purchaseItems,
                    {
                      item:
                        getKeyFromValue(gameData.ITEMS, item?.item ?? "") ??
                        "0",
                      equip: "1",
                    },
                  ];
                  setPurchaseItems(newPurchases);
                  upgradeHandler(undefined, undefined, newPurchases);
                  setActiveMenu(null);
                }}
              >
                Yes
              </Button>
              <Button
                size={"xs"}
                variant={"ghost"}
                onClick={() => {
                  const newPurchases = [
                    ...purchaseItems,
                    {
                      item:
                        getKeyFromValue(gameData.ITEMS, item?.item ?? "") ??
                        "0",
                      equip: "0",
                    },
                  ];
                  setPurchaseItems(newPurchases);
                  upgradeHandler(undefined, undefined, newPurchases);
                  setActiveMenu(null);
                }}
              >
                No
              </Button>{" "}
            </div>

            <Button size={"xs"} onClick={() => setActiveMenu(null)}>
              X
            </Button>
          </div>
        ) : (
          <Button
            onClick={() => {
              setActiveMenu(index);
            }}
            disabled={
              itemPrice > (adventurer?.gold ?? 0) ||
              !enoughGold ||
              checkTransacting(item.item ?? "") ||
              singlePurchaseExists(item.item ?? "") ||
              item.owner ||
              checkOwned(item.item ?? "") ||
              checkPurchased(item.item ?? "")
            }
            className={checkTransacting(item.item ?? "") ? "bg-white" : ""}
          >
            {!enoughGold || itemPrice > (adventurer?.gold ?? 0)
              ? "Not Enough Gold"
              : checkTransacting(item.item ?? "") ||
                singlePurchaseExists(item.item ?? "") ||
                checkPurchased(item.item ?? "")
              ? "In Cart"
              : checkOwned(item.item ?? "")
              ? "Owned"
              : "Purchase"}
          </Button>
        )}
      </td>
    </tr>
  );
};

export default MarketplaceRow;
