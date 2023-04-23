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
import {
  getLatestMarketItems,
  getAdventurersInList,
  getLatestMarketItemsNumber,
} from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";

const Marketplace: React.FC = () => {
  const { account } = useAccount();
  const { adventurer } = useAdventurer();
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { lootMarketArcadeContract, adventurerContract } = useContracts();
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
    loading: latestMarketItemsNumberLoading,
    error: latestMarketItemsNumberError,
    data: latestMarketItemsNumberData,
    refetch: latestMarketItemsNumberRefetch,
  } = useQuery(getLatestMarketItemsNumber, {
    pollInterval: 5000,
  });

  const latestMarketItemsNumber = latestMarketItemsNumberData
    ? latestMarketItemsNumberData.market[0].itemsNumber
    : [];

  const {
    loading: marketLatestItemsLoading,
    error: marketLatestItemsError,
    data: marketLatestItemsData,
    refetch: marketLatestItemsRefetch,
  } = useQuery(getLatestMarketItems, {
    variables: {
      itemsNumber: latestMarketItemsNumber,
    },
    pollInterval: 5000,
  });

  const marketLatestItems = marketLatestItemsData
    ? marketLatestItemsData.items
    : [];

  const bidders: number[] = [];

  for (const dict of marketLatestItems) {
    if (dict.bidder && !bidders.includes(dict.bidder)) {
      bidders.push(dict.bidder);
    }
  }

  const {
    loading: adventurersInListLoading,
    error: adventurersInListError,
    data: adventurersInListData,
    refetch: adventurersInListRefetch,
  } = useQuery(getAdventurersInList, {
    variables: {
      ids: bidders,
    },
    pollInterval: 5000,
  });

  const formatAdventurers = adventurersInListData
    ? adventurersInListData.adventurers
    : [];

  const mintDailyItemsTx = {
    contractAddress: lootMarketArcadeContract?.address,
    selector: "mint_daily_items",
    calldata: [],
    metadata: `Minting Loot Items!`,
  };

  // const equipItemTx = {
  //   contractAddress:
  //     adventurerContract?.address,
  //   selector: "equip_item",
  //   calldata: [
  //     itemId,
  //     "0",
  //     formatAdventurer.adventurer?.id,
  //     "0",
  //   ],
  //   metadata: `Equipping ${item.item}`,
  // };
  // addToCalls(equipItemTx);

  const convertExpiryTime = (expiry: string) => {
    const expiryTime = new Date(expiry);

    // Convert the offset to milliseconds
    const timezoneOffsetMilliseconds = 60 * 60 * 1000;

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
    "Claimed",
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
          <div className="h-screen-full overflow-auto w-full max-h-96">
            {marketLatestItemsLoading && (
              <p className="text-xl loading-ellipsis">LOADING</p>
            )}
            {marketLatestItemsError && (
              <p className="text-xl">ERROR {marketLatestItemsError.message}</p>
            )}
            <table className="w-full border-terminal-green border mt-4">
              <thead className="sticky top-0 ">
                <tr className="sticky top-0 border z-5 border-terminal-green bg-terminal-black">
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
                      <td className="text-center">
                        {item.bidder
                          ? `${
                              formatAdventurers.find(
                                (adventurer: any) =>
                                  adventurer.id == item.bidder
                              )?.name
                            } - ${item.bidder}`
                          : ""}
                      </td>
                      <td className="text-center">{item.expiry}</td>
                      <td className="text-center">{item.status}</td>
                      <td className="text-center">{item.claimedTime}</td>
                      <td className="text-center">
                        <Button
                          onClick={() => setShowBidBox(index)}
                          disabled={bidExists(item.marketId)}
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
                              contractAddress:
                                lootMarketArcadeContract?.address,
                              selector: "claim_item",
                              calldata: [
                                item.marketId,
                                "0",
                                formatAdventurer.adventurer?.id,
                                "0",
                              ],
                              metadata: `Claiming ${item.item}`,
                            };
                            addToCalls(claimItemTx);
                          }}
                          disabled={
                            claimExists(item.marketId) ||
                            !item.expiry ||
                            convertExpiryTime(item.expiry) > currentTime ||
                            formatAdventurer.adventurer?.id != item.bidder
                          }
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
