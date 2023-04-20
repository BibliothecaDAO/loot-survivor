import { MarketItem } from "../types";
import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { BidButton } from "./Bid";
import { Button } from "./Button";
import HorizontalKeyboardControl from "./HorizontalMenu";
import { useQuery } from "@apollo/client";
import { getLatestMarketItems } from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";

const Marketplace: React.FC = () => {
  const { account } = useAccount();
  const formatAddress = account ? account.address : "0x0";
  const { writeAsync, addToCalls, calls } = useWriteContract();
  const { lootMarketArcadeContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { hashes, addTransaction } = useTransactionManager();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const transactions = useTransactions({ hashes });
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

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

  console.log(marketLatestItems);

  const mintDailyItems = {
    contractAddress: lootMarketArcadeContract?.address,
    selector: "mint_daily_items",
    calldata: [],
  };

  const headings = [
    "Id",
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
      <div className="w-full">
        <Button
          onClick={() => {
            addToCalls(mintDailyItems);
            writeAsync().then((tx) => {
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
        <table className="w-full border-terminal-green border m-2">
          <thead>
            <tr className="p-3 border-b border-terminal-green">
              {headings.map((heading, index) => (
                <th key={index}>{heading}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {marketLatestItems.map((item: any, index: number) => (
              <tr key={index}>
                <td className="p-2 text-center">{item.id}</td>
                <td className="p-2 text-center">{item.slot}</td>
                <td className="p-2 text-center">{item.type}</td>
                <td className="p-2 text-center">{item.material}</td>
                <td className="p-2 text-center">{item.rank}</td>
                <td className="p-2 text-center">{item.prefix_1}</td>
                <td className="p-2 text-center">{item.prefix_2}</td>
                <td className="p-2 text-center">{item.suffix}</td>
                <td className="p-2 text-center">{item.greatness}</td>
                <td className="p-2 text-center">{item.createdBlock}</td>
                <td className="p-2 text-center">{item.xp}</td>
                <td className="p-2 text-center">{item.adventurer}</td>
                <td className="p-2 text-center">{item.bidder}</td>
                <td className="p-2 text-center">{item.price}</td>
                <td className="p-2 text-center">{item.expiry}</td>
                <td className="p-2 text-center">{item.status}</td>
                <td className="p-2 text-center">{item.claimedTime}</td>
                <td className="p-2 text-center">
                  <BidButton />
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
