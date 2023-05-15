import React, { useEffect, useState } from "react";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import { Metadata } from "../types";
import { Button } from "./Button";
import { MdClose } from "react-icons/md";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";

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

  const method = (queuedTransactions[0]?.metadata as Metadata)?.method;

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

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
        setNotification([
          ...notification,
          `You bid ${call.calldata[4]} gold on ${item?.item!}`,
        ]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Bidding"]);
      } else if (call.entrypoint === "claim_item") {
        const item = marketItems.find(
          (item: any) => item.marketId == call.calldata[0]
        );
        setNotification([...notification, `You claimed ${item?.item}!`]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Claiming"]);
      } else if (call.entrypoint === "equip_item") {
        const item = ownedItems.find(
          (item: any) => item.id == call.calldata[2]
        );
        setNotification([...notification, `You equipped ${item?.item}!`]);
        setLoadingQuery("adventurerByIdQuery");
        setLoadingMessage([...loadingMessage, "Equipping"]);
      } else if (call.entrypoint === "purchase_health") {
        setNotification([
          ...notification,
          `You purchased ${call.calldata[2]} health!`,
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
      <button
        onClick={toggleDropdown}
        className="relative flex p-2 bg-black border border-terminal-green"
      >
        {isOpen ? "Hide Cart" : "Show Cart"}
      </button>
      {isOpen ? (
        <div className="absolute right-[280px] top-32 z-10 w-[400px] h-[400px] p-3 bg-terminal-black border border-terminal-green">
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
                        onClick={() => removeFromCalls(call)}
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

                await handleSubmitCalls(writeAsync).then((tx: any) => {
                  if (tx) {
                    startLoading(
                      "Multicall",
                      tx?.transaction_hash,
                      loadingMessage,
                      loadingQuery,
                      adventurer?.id,
                      notification
                    );

                    addTransaction({
                      hash: tx.transaction_hash,
                      metadata: {
                        method: "Performing multicall",
                        description: "Transactions have been batched and sent!",
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
