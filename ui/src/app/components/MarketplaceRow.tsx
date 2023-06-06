import { useEffect, useState } from "react";
import { Button } from "./Button";
import { BidBox } from "./Bid";
import { useContracts } from "../hooks/useContracts";
import { formatTime } from "../lib/utils";
import { convertTime } from "../lib/utils";
import { Countdown } from "./Clock";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import LootIcon from "./LootIcon";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { Metadata } from "../types";

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
  const { lootMarketArcadeContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [showBidBox, setShowBidBox] = useState(-1);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { hashes, transactions } = useTransactionManager();
  const { data: txData } = useWaitForTransaction({ hash: hashes[0] });

  const transactingMarketIds = (transactions[0]?.metadata as Metadata)
    ?.marketIds;

  const currentTime = new Date().getTime();

  const bidExists = (marketId: number) => {
    return calls.some(
      (call: any) =>
        call.entrypoint == "bid_on_item" && call.calldata[0] == marketId
    );
  };

  const claimExists = (marketId: number) => {
    return calls.some(
      (call: any) =>
        call.entrypoint == "claim_item" && call.calldata[0] == marketId
    );
  };

  const checkBidBalance = () => {
    if (adventurer?.gold) {
      const sum = calls
        .filter((call) => call.entrypoint == "bid_on_item")
        .reduce((accumulator, current) => {
          const value = current.calldata[4];
          const parsedValue = value ? parseInt(value.toString(), 10) : 0;
          return accumulator + (isNaN(parsedValue) ? 0 : parsedValue);
        }, 0);
      return sum >= adventurer.gold;
    }
    return true;
  };

  const checkTransacting = (marketId: number) => {
    if (txData?.status == "RECEIVED" || txData?.status == "PENDING") {
      return transactingMarketIds?.includes(marketId);
    } else {
      return false;
    }
  };

  const checkBidder = (bidder: number) => {
    return adventurer?.id === bidder;
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

  const checkExpired = () => {
    const currentDate = new Date();
    const itemExpiryDate = new Date(convertTime(item.expiry));

    return itemExpiryDate < currentDate;
  };

  const status = () => {
    if (item.status == "Closed" && item.expiry == null) {
      return "No bids";
    } else if (item.expiry == null) {
      return "Open";
    } else if (checkExpired()) {
      return "Closed";
    } else {
      return "Bids";
    }
  };

  return (
    <tr
      className={
        "border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black" +
        (selectedIndex === index + 1 ? " bg-terminal-black" : "")
      }
    >
      <td className="text-center">{item.marketId}</td>
      <td className="text-center">{item.item}</td>
      <td className="text-center">{item.rank}</td>
      <td className="flex justify-center space-x-1 text-center ">
        {" "}
        <LootIcon className="self-center pt-3" type={item.slot} />{" "}
      </td>
      <td className="text-center">{item.type}</td>
      <td className="text-center">{item?.material || "Generic"}</td>
      <td className="text-center">{item.greatness}</td>
      <td className="text-center">{item.xp}</td>
      <td className="text-center">{item.price}</td>
      <td className="text-center">
        {item.bidder
          ? `${
              adventurers.find(
                (adventurer: any) => adventurer.id == item.bidder
              )?.name
            } - ${item.bidder}`
          : ""}
      </td>
      <td className="text-center">
        {item.expiry ? (
          <Countdown
            countingMessage=""
            finishedMessage="Expired"
            targetTime={new Date(convertTime(item.expiry))}
          />
        ) : (
          ""
        )}
      </td>

      <td className="text-center">{status()}</td>
      <td className="text-center">
        {item.claimedTime
          ? formatTime(new Date(convertTime(item.claimedTime)))
          : ""}
      </td>
      <td className="w-64 text-center">
        {showBidBox == index ? (
          <BidBox
            close={() => setShowBidBox(-1)}
            marketId={item.marketId}
            item={item}
            calculatedNewGold={calculatedNewGold}
          />
        ) : (
          <div>
            <Button
              onClick={() => setShowBidBox(index)}
              disabled={
                checkBidBalance() ||
                item.claimedTime ||
                (item.expiry && checkExpired()) ||
                bidExists(item.marketId) ||
                checkTransacting(item.marketId)
                // checkBidder(item.bidder)
              }
              className={bidExists(item.marketId) ? "bg-white" : ""}
            >
              bid
            </Button>
            <Button
              onClick={async () => {
                const claimItemTx = {
                  contractAddress: lootMarketArcadeContract?.address ?? "",
                  entrypoint: "claim_item",
                  calldata: [item.marketId, "0", adventurer?.id, "0"],
                  metadata: `Claiming ${item.item}`,
                };
                addToCalls(claimItemTx);
              }}
              disabled={
                item.claimedTime ||
                claimExists(item.marketId) ||
                !item.expiry ||
                convertTime(item.expiry) > currentTime ||
                adventurer?.id != item.bidder ||
                checkTransacting(item.marketId)
              }
              className={claimExists(item.marketId) ? "" : ""}
            >
              claim
            </Button>
          </div>
        )}
      </td>
    </tr>
  );
};

export default MarketplaceRow;
