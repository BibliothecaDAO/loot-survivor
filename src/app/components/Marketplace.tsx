import { MarketItem } from "../types";
import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { BidBox } from "./Bid";
import { Button } from "./Button";
import HorizontalKeyboardControl from "./HorizontalMenu";
import { useQuery } from "@apollo/client";
import { getLatestMarketItems } from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";

const Marketplace: React.FC = () => {
  const { account } = useAccount();
  const { adventurer } = useAdventurer();
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { lootMarketArcadeContract } = useContracts();
  const { hashes, addTransaction } = useTransactionManager();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const [showBidBox, setShowBidBox] = useState(-1);

  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const formatAddress = account ? account.address : "0x0";
  const transactions = useTransactions({ hashes });
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const {
    loading: marketLatestItemsLoading,
    error: marketLatestItemsError,
    data: marketLatestItemsData,
    refetch: marketLatestItemsRefetch,
  } = useQuery(getLatestMarketItems, {
    pollInterval: 5000,
  });

  const marketLatestItems = marketLatestItemsData
    ? marketLatestItemsData.items
    : [];

  const mintDailyItemsTx = {
    contractAddress: lootMarketArcadeContract?.address,
    selector: "mint_daily_items",
    calldata: [],
  };

  const claimItemTx = {
    contractAddress: lootMarketArcadeContract?.address,
    selector: "claim_item",
    calldata: [
      marketLatestItemsData?.marketId,
      "0",
      formatAdventurer.adventurer?.id,
      "0",
    ],
  };

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

  const headings = [
    "Market Id",
    "Item",
    "Rank",
    "Slot",
    "Type",
    "Material",
    "Greatness",
    "XP",
    "Price",
    "Bidder",
    "Expiry",
    "Status",
    "Actions",
  ];

  return (
    <>
      {adventurer?.adventurer?.level != 1 ? (
        <div className="w-full">
          <div className="flex flex-row m-1">
            <Button onClick={() => addToCalls(mintDailyItemsTx)}>
              Mint daily items
            </Button>
          </div>
          <div className="h-[430px] overflow-auto w-full">
            {marketLatestItemsLoading && (
              <p className="text-xl loading-ellipsis">LOADING</p>
            )}
            {marketLatestItemsError && (
              <p className="text-xl">ERROR {marketLatestItemsError.message}</p>
            )}
            <table className="w-full border-terminal-green border min-width: 640px">
              <thead>
                <tr className="sticky top-0 border border-terminal-green bg-terminal-black">
                  {headings.map((heading, index) => (
                    <th key={index}>{heading}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {!marketLatestItemsLoading &&
                  !marketLatestItemsError &&
                  marketLatestItems.map((item: any, index: number) => (
                    <tr
                      key={index}
                      className="border-b border-terminal-green hover:bg-terminal-black"
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
                      <td className="text-center">{item.bidder}</td>
                      <td className="text-center">{item.expiry}</td>
                      <td className="text-center">{item.status}</td>
                      <td className="text-center">
                        <Button
                          onClick={() => setShowBidBox(index)}
                          disabled={bidExists(item.marketId)}
                          className={bidExists(item.marketId) ? "bg-white" : ""}
                        >
                          Bid
                        </Button>
                        <BidBox
                          showBidBox={showBidBox == index}
                          close={() => setShowBidBox(-1)}
                          marketId={item.marketId}
                        />
                        <Button
                          onClick={() => addToCalls(claimItemTx)}
                          disabled={claimExists(item.marketId)}
                          className={
                            claimExists(item.marketId) ? "bg-white" : ""
                          }
                        >
                          CLAIM
                        </Button>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="flex w-full mt-[200px]">
          <p className="mx-auto items-center text-[50px] animate-pulse">
            Adventurer must be level 2 or higher to access Market!
          </p>
        </div>
      )}
    </>
  );
};

export default Marketplace;

// onClick={async () => {
//   addToCalls(mintDailyItems);
//   await writeAsync().then((tx: any) => {
//     setHash(tx.transaction_hash);
//     addTransaction({
//       hash: tx.transaction_hash,
//       metadata: {
//         method: "Minting loot items",
//         description: "Market Items are being minted!",
//       },
//     });
//   });
// }}
