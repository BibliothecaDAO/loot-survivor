import React, { useEffect, useState } from "react";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import { Metadata } from "../types";
import { Button } from "./Button";
import { MdClose } from "react-icons/md";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import { processItemName } from "../lib/utils";
import {
  getLatestMarketItems,
  getItemsByAdventurer,
} from "../hooks/graphql/queries";
import useCustomQuery from "../hooks/useCustomQuery";
import useUIStore from "../hooks/useUIStore";
import { useUiSounds } from "../hooks/useUiSound";
import { soundSelector } from "../hooks/useUiSound";

const TransactionCart: React.FC = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const removeFromCalls = useTransactionCartStore(
    (state) => state.removeFromCalls
  );
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const resetCalls = useTransactionCartStore((state) => state.resetCalls);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const {
    hashes,
    transactions: queuedTransactions,
    addTransaction,
  } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const [isOpen, setIsOpen] = useState(false);
  const [notification, setNotification] = useState<string[]>([]);
  const [loadingMessage, setLoadingMessage] = useState<string[]>([]);
  const [loadingQuery, setLoadingQuery] = useState("");
  const { data } = useQueriesStore();
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const method = (queuedTransactions[0]?.metadata as Metadata)?.method;

  // useCustomQuery(
  //   "latestMarketItemsQuery",
  //   getLatestMarketItems,
  //   undefined,
  //   false
  // );

  // useCustomQuery(
  //   "itemsByAdventurerQuery",
  //   getItemsByAdventurer,
  //   undefined,
  //   false
  // );

  const marketItems = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
    : [];

  const ownedItems = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  // const reorderCards = useCallback((dragIndex: number, hoverIndex: number) => {
  //   txQueue.reorderQueue(dragIndex, hoverIndex);
  // }, []);

  const handleLoadData = () => {
    for (let call of calls) {
      if (call.entrypoint === "mint_daily_items") {
        setNotification([...notification, "New items minted!"]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Minting Items"]);
      } else if (call.entrypoint === "bid_on_item") {
        const item = marketItems.find(
          (item: any) => item.marketId == call.calldata[0]
        );
        const itemName = processItemName(item);
        setNotification([
          ...notification,
          `You bid ${call.calldata[4]} gold on ${item?.item && itemName}`,
        ]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Bidding"]);
      } else if (call.entrypoint === "claim_item") {
        const item = marketItems.find(
          (item: any) => item.marketId == call.calldata[0]
        );
        const itemName = processItemName(item);
        setNotification([
          ...notification,
          `You claimed ${item?.item && itemName}!`,
        ]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Claiming"]);
      } else if (call.entrypoint === "equip_item") {
        const item = ownedItems.find(
          (item: any) => item.id == call.calldata[2]
        );
        const itemName = processItemName(item);
        setNotification([
          ...notification,
          `You equipped ${item?.item && itemName}!`,
        ]);
        setLoadingQuery("adventurerByIdQuery");
        setLoadingMessage([...loadingMessage, "Equipping"]);
      } else if (call.entrypoint === "purchase_health") {
        setNotification([
          ...notification,
          `You purchased ${
            call.calldata[2] && parseInt(call.calldata[2].toString()) * 10
          } health!`,
          // `You purchased ${parseInt(call.calldata[2].toString()) * 10} health!`,
        ]);
        setLoadingQuery("adventurerByIdQuery");
        setLoadingMessage([...loadingMessage, "Purchasing Health"]);
      }
    }
  };

  useEffect(() => {
    handleLoadData();
  }, [calls]);

  return (
    <>
      {displayCart ? (
        <div className="absolute right-[50px] w-[300px] h-[400px] sm:right-[280px] top-20 sm:top-32 z-10 sm:w-[400px] sm:h-[400px] p-3 bg-terminal-black border border-terminal-green">
          <p className="text-2xl">TRANSACTIONS</p>
          <div className="w-full border border-terminal-green "></div>
          <div className="flex flex-col h-[200px] overflow-auto">
            {calls.map((call: any, i: number) => (
              <div key={i}>
                <div className="flex flex-col gap-2">
                  {call && (
                    <div className="flex items-center justify-between">
                      <p>{call.entrypoint}</p>
                      {/* <p>{call.calldata}</p> */}
                      <p>{call.metadata}</p>
                      <button
                        onClick={() => {
                          removeFromCalls(call);
                          clickPlay();
                        }}
                        className="text-red-500 hover:text-red-700"
                      >
                        <MdClose size={20} />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
          <div className="flex flex-row gap-2 absolute bottom-4">
            <Button
              onClick={async () => {
                const marketIds: any[] = [];

                for (const dict of calls) {
                  if (
                    dict.hasOwnProperty("entrypoint") &&
                    (dict["entrypoint"] === "bid_on_item" ||
                      dict["entrypoint"] === "claim_item")
                  ) {
                    marketIds.push(dict.calldata[0]);
                  }
                }
                startLoading(
                  "Multicall",
                  loadingMessage,
                  loadingQuery,
                  adventurer?.id,
                  notification
                );

                await handleSubmitCalls(writeAsync).then((tx: any) => {
                  if (tx) {
                    setTxHash(tx?.transaction_hash);
                    addTransaction({
                      hash: tx.transaction_hash,
                      metadata: {
                        method: "Multicall",
                        marketIds: marketIds,
                      },
                    });
                  }
                });
              }}
            >
              Submit all Transactions
            </Button>
            <Button onClick={() => resetCalls()}>Clear Cart</Button>
          </div>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
