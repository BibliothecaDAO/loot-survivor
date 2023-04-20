import { MarketItem } from "../types";
import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
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
  const { writeAsync, addToCalls, calls } = useTransactionCart();
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

  const mintDailyItems = {
    contractAddress: lootMarketArcadeContract?.address,
    selector: "mint_daily_items",
    calldata: [],
  };

  const bidExists = (marketId: number) => {
    return calls.some(
      (call: any) =>
        call.entrypoint == "bid_on_item" && call.calldata[2] == marketId
    );
  };

  const headings = [
    "Market Id",
    "Slot",
    "Type",
    "Material",
    "Rank",
    "Prefix_1",
    "Prefix_2",
    "Suffix",
    "Greatness",
    "CreatedBlock",
    "XP",
    "Adventurer",
    "Bidder",
    "Price",
    "Expiry",
    "Status",
    "Claimed Time",
    "Actions",
  ];

  return (
    <div className="w-full">
      <div className="flex flex-row m-1">
        <Button
          onClick={async () => {
            addToCalls(mintDailyItems);
            await writeAsync().then((tx: any) => {
              setHash(tx.transaction_hash);
              addTransaction({
                hash: tx.transaction_hash,
                metadata: {
                  method: "Minting loot items",
                  description: "Market Items are being minted!",
                },
              });
            });
          }}
        >
          Mint daily items
        </Button>
      </div>
      <div className="h-[430px] overflow-auto w-full">
        {marketLatestItemsLoading && (
          <p className="text-xl loading-ellipsis">LOADING...GETTING DATA</p>
        )}
        {marketLatestItemsError && (
          <p className="text-xl"> ERROR... {marketLatestItemsError.message}</p>
        )}
        <table className="w-full border-terminal-green border">
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
                  <td className=" text-center">{item.marketid}</td>
                  <td className=" text-center">{item.slot}</td>
                  <td className=" text-center">{item.type}</td>
                  <td className=" text-center">{item.material}</td>
                  <td className=" text-center">{item.rank}</td>
                  <td className=" text-center">{item.prefix_1}</td>
                  <td className=" text-center">{item.prefix_2}</td>
                  <td className=" text-center">{item.suffix}</td>
                  <td className=" text-center">{item.greatness}</td>
                  <td className=" text-center">{item.createdBlock}</td>
                  <td className=" text-center">{item.xp}</td>
                  <td className=" text-center">{item.adventurer}</td>
                  <td className=" text-center">{item.bidder}</td>
                  <td className=" text-center">{item.price}</td>
                  <td className=" text-center">{item.expiry}</td>
                  <td className=" text-center">{item.status}</td>
                  <td className=" text-center">{item.claimedTime}</td>
                  <td className=" text-center">
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
                    <Button>CLAIM</Button>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Marketplace;
