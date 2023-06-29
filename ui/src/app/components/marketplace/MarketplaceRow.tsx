import { useEffect, useState } from "react";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import { getItemData } from "../../lib/utils";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import LootIcon from "../icons/LootIcon";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { Metadata } from "../../types";

interface MarketplaceRowProps {
  item: any;
  index: number;
  selectedIndex: number;
  adventurers: any[];
  isActive: boolean;
  setActiveMenu: (value: any) => void;
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

  const transactingMarketIds = (transactions[0]?.metadata as Metadata)?.items;

  const purchaseExists = (itemId: number) => {
    return calls.some(
      (call: any) => call.entrypoint == "buy_item" && call.calldata[1] == itemId
    );
  };

  const checkPurchaseBalance = () => {
    if (adventurer?.gold) {
      const sum = calls
        .filter((call) => call.entrypoint == "buy_item")
        .reduce((accumulator, current) => {
          return accumulator + (isNaN(item.price) ? 0 : item.price);
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

  const handleKeyDown = (event: KeyboardEvent) => {
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
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [isActive]);

  const handlePurchase = (itemId: number, equip: boolean) => {
    if (gameContract) {
      const PurchaseTx = {
        contractAddress: gameContract?.address,
        entrypoint: "buy_item",
        calldata: [adventurer?.id, itemId, equip],
        metadata: `Bidding on ${item.item}`,
      };
      addToCalls(PurchaseTx);
      // Place bid logic
      close();
    }
  };

  const { tier, type, slot } = getItemData(item.item);

  return (
    <tr
      className={
        "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black" +
        (selectedIndex === index + 1 ? " bg-terminal-black" : "")
      }
    >
      <td className="text-center">{item.item}</td>
      <td className="text-center">{tier}</td>
      <td className="flex justify-center space-x-1 text-center ">
        {" "}
        <LootIcon className="self-center pt-3" type={slot} />{" "}
      </td>
      <td className="text-center">{type}</td>
      <td className="text-center">{item.price}</td>

      <td className="w-64 text-center">
        {showEquipQ ? (
          <div className="flex flex-row">
            <Button onClick={() => handlePurchase(item.item, true)}>Yes</Button>
            <Button onClick={() => handlePurchase(item.item, false)}>No</Button>
          </div>
        ) : (
          <Button
            onClick={() => setShowEquipQ(true)}
            disabled={checkPurchaseBalance() || checkTransacting(item.item)}
            className={checkTransacting(item.item) ? "bg-white" : ""}
          >
            Purchase
          </Button>
        )}
      </td>
    </tr>
  );
};

export default MarketplaceRow;
