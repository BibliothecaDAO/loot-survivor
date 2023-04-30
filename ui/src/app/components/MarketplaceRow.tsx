import { useEffect, useState } from "react";
import { Button } from "./Button";
import { BidBox } from "./Bid";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { formatTime } from "../lib/utils";

interface MarketplaceRowProps {
  ref: any;
  item: any;
  index: number;
  selectedIndex: number;
  adventurers: any[];
  isActive: boolean;
  setActiveMenu: (value: any) => void;
}

const MarketplaceRow = ({
  ref,
  item,
  index,
  selectedIndex,
  adventurers,
  isActive,
  setActiveMenu,
}: MarketplaceRowProps) => {
  const [selectedButton, setSelectedButton] = useState<number>(0);
  const { lootMarketArcadeContract, adventurerContract } = useContracts();
  const { adventurer } = useAdventurer();
  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;
  const [showBidBox, setShowBidBox] = useState(-1);
  const { calls, addToCalls } = useTransactionCart();

  const convertExpiryTime = (expiry: string) => {
    const expiryTime = new Date(expiry);

    // Convert the offset to milliseconds
    const currentTimezoneOffsetMinutes = new Date().getTimezoneOffset() * -1;
    const timezoneOffsetMilliseconds = currentTimezoneOffsetMinutes * 60 * 1000;

    // Add the offset to the expiry time to get the correct UTC Unix timestamp
    const expiryTimeUTC = expiryTime.getTime() + timezoneOffsetMilliseconds;
    return expiryTimeUTC;
  };

  const currentTime = new Date().getTime(); // Get the current time in milliseconds

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
    if (formatAdventurer?.gold) {
      const sum = calls
        .filter((call: any) => call.entrypoint == "bid_on_item")
        .reduce(
          (accumulator, current) => accumulator + (current.calldata[4] || 0),
          0
        );
      return sum >= formatAdventurer.gold;
    }
    return true;
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

  return (
    <tr
      ref={ref}
      className={
        "border-b border-terminal-green hover:bg-terminal-black" +
        (selectedIndex === index + 1 ? " bg-terminal-black" : "")
      }
    >
      <td className="text-center">{item.marketId}</td>
      <td className="text-center">{item.item}</td>
      <td className="text-center">{item.rank}</td>
      <td className="text-center">{item.slot}</td>
      <td className="text-center">{item.type}</td>
      <td className="text-center">{item.material}</td>
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
      <td className="text-center">{formatTime(new Date(item.expiry))}</td>
      <td className="text-center">{item.status}</td>
      <td className="text-center">{item.claimedTime}</td>
      <td className="text-center">
        <Button
          onClick={() => setShowBidBox(index)}
          disabled={bidExists(item.marketId) || checkBidBalance()}
          className={bidExists(item.marketId) ? "bg-white" : ""}
        >
          BID
        </Button>
        <BidBox
          showBidBox={showBidBox == index}
          close={() => setShowBidBox(-1)}
          marketId={item.marketId}
          item={item}
        />
        <Button
          onClick={async () => {
            const claimItemTx = {
              contractAddress: lootMarketArcadeContract?.address,
              selector: "claim_item",
              calldata: [item.marketId, "0", formatAdventurer?.id, "0"],
              metadata: `Claiming ${item.item}`,
            };
            addToCalls(claimItemTx);
          }}
          disabled={
            item.claimedTime ||
            claimExists(item.marketId) ||
            !item.expiry ||
            convertExpiryTime(item.expiry) > currentTime ||
            currentTime - convertExpiryTime(item.expiry) < 30 * 60 * 1000 ||
            formatAdventurer?.id != item.bidder
          }
          className={claimExists(item.marketId) ? "bg-white" : ""}
        >
          CLAIM
        </Button>
      </td>
    </tr>
  );
};

export default MarketplaceRow;
