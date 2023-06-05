import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useAccount } from "@starknet-react/core";
import { NullAdventurerProps } from "../types";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";

interface BidBoxProps {
  close: () => void;
  marketId: number;
  item: any;
  calculatedNewGold: number;
}

export function BidBox({
  close,
  marketId,
  item,
  calculatedNewGold,
}: BidBoxProps) {
  const { account } = useAccount();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { lootMarketArcadeContract } = useContracts();
  const [bidPrice, setBidPrice] = useState<number | undefined>(undefined);
  const adventurerCharisma = adventurer?.charisma ?? 0;

  const formatAddress = account ? account.address : "0x0";

  const basePrice = 3 * (6 - item.rank);

  const discount = adventurerCharisma * 3;
  const actualBid = bidPrice ? bidPrice + discount : 0;
  const neededBid = item.price
    ? item.price + 1
    : basePrice - discount > 3
    ? basePrice - discount
    : 3;
  console.log(neededBid);

  const handleBid = (marketId: number) => {
    if (bidPrice != undefined && actualBid >= basePrice) {
      if (lootMarketArcadeContract && formatAddress) {
        const BidTx = {
          contractAddress: lootMarketArcadeContract?.address,
          entrypoint: "bid_on_item",
          calldata: [marketId, "0", adventurer?.id, "0", bidPrice],
          metadata: `Bidding on ${item.item}`,
        };
        addToCalls(BidTx);
        // Place bid logic
        close();
      }
    } else {
      alert(`Bid price must be at least ${neededBid} gold`);
    }
  };

  return (
    <div className="flex w-full">
      <input
        id="bid"
        type="number"
        min={neededBid}
        placeholder={neededBid.toString()}
        onChange={(e) => setBidPrice(parseInt(e.target.value, 10))}
        className="w-16 px-3 py-2 border rounded-md bg-terminal-black border-terminal-green text-terminal-green"
      />
      <Button
        onClick={() => handleBid(marketId)}
        disabled={
          typeof bidPrice === "undefined" ||
          item.price >= actualBid ||
          bidPrice > calculatedNewGold ||
          actualBid < basePrice
        }
      >
        Place Bid
      </Button>
      <Button variant={"outline"} onClick={() => close()}>
        Close
      </Button>
    </div>
  );
}
