import { useState } from "react";
import { Button } from "./Button";

export function BidButton() {
  const [showBidBox, setShowBidBox] = useState(false);
  const [bidPrice, setBidPrice] = useState<number | undefined>(undefined);

  const handleBid = () => {
    if (bidPrice !== undefined && bidPrice >= 3) {
      // Place bid logic
      console.log(`Bid placed for ${bidPrice} gold`);
      setShowBidBox(false);
    } else {
      alert("Bid price must be at least 3 gold");
    }
  };

  return (
    <>
      <Button onClick={() => setShowBidBox(true)}>Bid</Button>
      {showBidBox && (
        <div className="absolute right-0 mt-2 p-2 bg-white border border-gray-300 rounded-md shadow-lg">
          <div className="flex items-center justify-between mb-2">
            <label htmlFor="bid-price">Bid price (minimum 3 gold)</label>
            <Button onClick={() => setShowBidBox(false)}>Close</Button>
          </div>
          <input
            id="bid-price"
            type="number"
            min="3"
            onChange={(e) => setBidPrice(parseInt(e.target.value, 10))}
            className="border border-gray-300 rounded-md px-3 py-2"
          />
          <Button onClick={handleBid} className="mt-2">
            Place Bid
          </Button>
        </div>
      )}
    </>
  );
}
