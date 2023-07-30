import { useCallback, useEffect, useState } from "react";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import { getItemData, getItemPrice, getKeyFromValue } from "../../lib/utils";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import LootIcon from "../icons/LootIcon";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { Metadata, Item, Adventurer, Call, ItemPurchase } from "../../types";
import { CoinIcon } from "../icons/Icons";
import EfficacyDisplay from "../icons/EfficacyIcon";
import { GameData } from "../GameData";
import { useMediaQuery } from "react-responsive";

interface MarketplaceRowProps {
  item: Item;
  index: number;
  selectedIndex: number;
  adventurers: Adventurer[];
  activeMenu: number | null;
  setActiveMenu: (value: number | null) => void;
  calculatedNewGold: number;
  ownedItems: Item[];
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
}

const MarketplaceRow = ({
  item,
  index,
  selectedIndex,
  adventurers,
  activeMenu,
  setActiveMenu,
  calculatedNewGold,
  ownedItems,
  purchaseItems,
  setPurchaseItems,
}: MarketplaceRowProps) => {
  const [selectedButton, setSelectedButton] = useState<number>(0);
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });
  // const setPurchasedItem = useUIStore((state) => state.setPurchasedItem);

  const transactingMarketIds = (transactions[0]?.metadata as Metadata)?.items;

  const gameData = new GameData();

  const singlePurchaseExists = (item: string) => {
    // return calls.some(
    //   (call: Call) =>
    //     call.entrypoint == "buy_items_and_upgrade_stats" &&
    //     Array.isArray(call.calldata) &&
    //     call.calldata[2] == getKeyFromValue(gameData.ITEMS, item)?.toString()
    // );
    return purchaseItems.some(
      (purchasingItem: ItemPurchase) => purchasingItem.item == item
    );
  };

  const { tier, type, slot } = getItemData(item.item ?? "");
  const itemPrice = getItemPrice(tier, adventurer?.charisma ?? 0);
  const enoughGold = calculatedNewGold >= itemPrice;

  const checkTransacting = (item: string) => {
    if (txData?.status == "RECEIVED" || txData?.status == "PENDING") {
      return transactingMarketIds?.includes(item);
    } else {
      return false;
    }
  };

  const checkOwned = (item: string) => {
    return ownedItems.some((ownedItem) => ownedItem.item == item);
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

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <tr
      className={
        "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black" +
        (selectedIndex === index + 1 ? " bg-terminal-black" : "")
      }
    >
      <td className="text-center">{item.item}</td>
      <td className="text-center">{tier}</td>
      <td className="text-center">
        <div className="flex justify-center items-center">
          <LootIcon size={isMobileDevice ? "w-4" : "w-5"} type={slot} />
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
            {getItemPrice(tier, adventurer?.charisma ?? 0)}
          </p>
        </div>
      </td>

      <td className="w-20 sm:w-32 text-center">
        {!isMobileDevice && activeMenu === index ? (
          <div className="flex flex-row items-center justify-center gap-2">
            <p>Equip?</p>
            <div className="flex flex-col">
              <Button
                size={"xs"}
                variant={"ghost"}
                onClick={() => {
                  setPurchaseItems([
                    ...purchaseItems,
                    {
                      item:
                        getKeyFromValue(gameData.ITEMS, item?.item ?? "") ??
                        "0",
                      equip: "1",
                    },
                  ]);
                  setActiveMenu(null);
                }}
              >
                Yes
              </Button>
              <Button
                size={"xs"}
                variant={"ghost"}
                onClick={() => {
                  setPurchaseItems([
                    ...purchaseItems,
                    {
                      item:
                        getKeyFromValue(gameData.ITEMS, item?.item ?? "") ??
                        "0",
                      equip: "0",
                    },
                  ]);
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
              (isMobileDevice && activeMenu === index && isActive) ||
              checkOwned(item.item ?? "")
            }
            className={checkTransacting(item.item ?? "") ? "bg-white" : ""}
          >
            {!enoughGold || itemPrice > (adventurer?.gold ?? 0)
              ? "Not Enough Gold"
              : checkTransacting(item.item ?? "") ||
                singlePurchaseExists(item.item ?? "") ||
                (isMobileDevice && activeMenu === index && isActive)
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
