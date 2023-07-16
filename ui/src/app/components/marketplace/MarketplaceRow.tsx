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
import { Metadata, Item, Adventurer, Call } from "../../types";
import { CoinIcon } from "../icons/Icons";
import EfficacyDisplay from "../icons/EfficacyIcon";
import { GameData } from "../GameData";
import { useMediaQuery } from "react-responsive";

interface MarketplaceRowProps {
  item: Item;
  index: number;
  selectedIndex: number;
  adventurers: Adventurer[];
  isActive: boolean;
  setActiveMenu: (value: number) => void;
  calculatedNewGold: number;
}

const MarketplaceRow = ({
  item,
  index,
  selectedIndex,
  adventurers,
  isActive,
  setActiveMenu,
  calculatedNewGold,
}: MarketplaceRowProps) => {
  const [selectedButton, setSelectedButton] = useState<number>(0);
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [showEquipQ, setShowEquipQ] = useState(false);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });
  // const setPurchasedItem = useUIStore((state) => state.setPurchasedItem);

  const transactingMarketIds = (transactions[0]?.metadata as Metadata)?.items;

  const gameData = new GameData();

  const singlePurchaseExists = (item: string) => {
    return calls.some(
      (call: Call) =>
        call.entrypoint == "buy_item" &&
        Array.isArray(call.calldata) &&
        call.calldata[2] == getKeyFromValue(gameData.ITEMS, item)?.toString()
    );
  };

  const purchaseExists = () => {
    return calls.some((call: Call) => call.entrypoint == "buy_item");
  };

  const { tier, type, slot } = getItemData(item.item ?? "");
  const itemPrice = getItemPrice(tier, adventurer?.charisma ?? 0);

  const checkPurchaseBalance = () => {
    if (adventurer?.gold) {
      const sum = calls
        .filter((call) => call.entrypoint == "buy_item")
        .reduce((accumulator, current) => {
          return accumulator + (isNaN(itemPrice) ? 0 : itemPrice);
        }, 0);
      return sum >= adventurer.gold;
    }
    return true;
  };

  const checkTransacting = (item: string) => {
    if (txData?.status == "RECEIVED" || txData?.status == "PENDING") {
      return transactingMarketIds?.includes(item);
    } else {
      return false;
    }
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

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [isActive, handleKeyDown]);

  const handlePurchase = (item: string, tier: number, equip: boolean) => {
    if (gameContract) {
      const gameData = new GameData();
      const PurchaseTx = {
        contractAddress: gameContract?.address,
        entrypoint: "buy_item",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
          getKeyFromValue(gameData.ITEMS, item)?.toString() ?? "",
          equip ? "1" : "0",
        ],
        metadata: `Purchasing ${item} for ${getItemPrice(
          tier,
          adventurer?.charisma ?? 0
        )} gold`,
      };
      addToCalls(PurchaseTx);
    }
  };

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <>
      <tr
        className={
          "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black" +
          (selectedIndex === index + 1 ? " bg-terminal-black" : "")
        }
      >
        <td className="text-center">{item.item}</td>
        <td className="text-center">{tier}</td>
        <td className="text-center">
          <div className="flex justify-center items-center ">
            <LootIcon className="sm:w-4" type={slot} />
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

        <td className="w-32 text-center">
          {!isMobileDevice && showEquipQ ? (
            <div className="flex flex-row items-center justify-center gap-2">
              <p>Equip?</p>
              <div className="flex flex-col">
                <Button
                  size={"xs"}
                  variant={"ghost"}
                  onClick={() => {
                    handlePurchase(item.item ?? "", tier, true);
                    setShowEquipQ(false);
                    // setPurchasedItem(true);
                  }}
                >
                  Yes
                </Button>
                <Button
                  size={"xs"}
                  variant={"ghost"}
                  onClick={() => {
                    handlePurchase(item.item ?? "", tier, false);
                    setShowEquipQ(false);
                    // setPurchasedItem(true);
                  }}
                >
                  No
                </Button>{" "}
              </div>

              <Button size={"xs"} onClick={() => setShowEquipQ(false)}>
                X
              </Button>
            </div>
          ) : (
            <Button
              onClick={() => {
                setShowEquipQ(true);
                setActiveMenu(index + 1);
              }}
              disabled={
                itemPrice > (adventurer?.gold ?? 0) ||
                checkPurchaseBalance() ||
                checkTransacting(item.item ?? "") ||
                singlePurchaseExists(item.item ?? "") ||
                item.owner ||
                (isMobileDevice && showEquipQ && isActive)
              }
              className={checkTransacting(item.item ?? "") ? "bg-white" : ""}
            >
              {checkPurchaseBalance() || itemPrice > (adventurer?.gold ?? 0)
                ? "Not Enough Gold"
                : checkTransacting(item.item ?? "") ||
                  singlePurchaseExists(item.item ?? "") ||
                  (isMobileDevice && showEquipQ && isActive)
                ? "In Cart"
                : item.owner
                ? "Owned"
                : "Purchase"}
            </Button>
          )}
        </td>
      </tr>
      {isMobileDevice && showEquipQ && isActive && (
        <div className="fixed bottom-40 left-25 flex flex-row items-center justify-center gap-2">
          <p>{`Equip ${item.item} ?`}</p>
          <Button
            onClick={() => {
              handlePurchase(item.item ?? "", tier, true);
              setShowEquipQ(false);
              // setPurchasedItem(true);
            }}
          >
            Yes
          </Button>
          <Button
            onClick={() => {
              handlePurchase(item.item ?? "", tier, false);
              setShowEquipQ(false);
              // setPurchasedItem(true);
            }}
          >
            No
          </Button>
          <Button onClick={() => setShowEquipQ(false)}>Cancel</Button>
        </div>
      )}
    </>
  );
};

export default MarketplaceRow;
