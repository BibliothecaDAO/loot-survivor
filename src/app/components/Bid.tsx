import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";

interface BidBoxProps {
  showBidBox: Boolean;
  close: () => void;
  marketId: number;
}

export function BidBox({ showBidBox, close, marketId }: BidBoxProps) {
  const { account } = useAccount();
  const { adventurer } = useAdventurer();
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { lootMarketArcadeContract } = useContracts();
  const { hashes, addTransaction } = useTransactionManager();
  const transactions = useTransactions({ hashes });
  const [bidPrice, setBidPrice] = useState<number | undefined>(undefined);

  const formatAddress = account ? account.address : "0x0";
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const handleBid = (marketId: number) => {
    if (bidPrice != undefined && bidPrice >= 3) {
      if (lootMarketArcadeContract && formatAddress) {
        const BidTx = {
          contractAddress: lootMarketArcadeContract?.address,
          selector: "bid_on_item",
          calldata: [
            marketId,
            "0",
            formatAdventurer.adventurer?.id,
            "0",
            bidPrice,
          ],
          metadata: `Bidding on ${marketId}`,
        };
        addToCalls(BidTx);
        // Place bid logic
        console.log(`Bid placed for ${bidPrice} gold`);
        close();
      }
    } else {
      alert("Bid price must be at least 3 gold");
    }
  };

  return (
    <>
      {showBidBox && (
        <div className="relative right-0 mt-2 p-2 bg-black border border-terminal-green rounded-md shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <label>Bid price (minimum 3 gold)</label>
            <Button onClick={() => close()}>Close</Button>
          </div>
          <input
            id="bid"
            type="number"
            min="3"
            onChange={(e) => setBidPrice(parseInt(e.target.value, 10))}
            className="border border-terminal-black rounded-md px-3 py-2"
          />
          <Button onClick={() => handleBid(marketId)} className="mt-2">
            Place Bid
          </Button>
        </div>
      )}
    </>
  );
}
