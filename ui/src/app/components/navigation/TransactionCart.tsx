import React, { useCallback, useEffect, useState } from "react";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import { Button } from "../buttons/Button";
import { MdClose } from "react-icons/md";
import useLoadingStore from "../../hooks/useLoadingStore";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { processItemName, getItemPrice, getItemData } from "../../lib/utils";
import useUIStore from "../../hooks/useUIStore";
import { useUiSounds } from "../../hooks/useUiSound";
import { soundSelector } from "../../hooks/useUiSound";
import { Item, NullItem, Call, NullAdventurer } from "../../types";

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
  const [notification, setNotification] = useState<string[]>([]);
  const [loadingMessage, setLoadingMessage] = useState<string[]>([]);
  const [loadingQuery, setLoadingQuery] = useState("");
  const { data } = useQueriesStore();
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const items = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
    : [];

  const ownedItems = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  // const slayedAdventurer = data.adventurerToSlayQuery
  //   ? data.adventurerToSlayQuery.adventurers?[0]
  //   : NullAdventurer;

  const handleLoadData = useCallback(() => {
    for (let call of calls) {
      if (call.entrypoint === "buy_item") {
        const item = items.find((item: Item) => item.item == call.calldata[0]);
        const itemName = processItemName(item ?? NullItem);
        const { tier } = getItemData(item?.item ?? "");
        setNotification([
          ...notification,
          `You purchased ${item?.item && itemName} for ${getItemPrice(
            tier
          )} gold`,
        ]);
        setLoadingQuery("latestMarketItemsQuery");
        setLoadingMessage([...loadingMessage, "Purchasing"]);
      } else if (call.entrypoint === "equip_item") {
        const item = ownedItems.find(
          (item: Item) => item.item == call.calldata[2]
        );
        const itemName = processItemName(item ?? NullItem);
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
        ]);
        setLoadingQuery("adventurerByIdQuery");
        setLoadingMessage([...loadingMessage, "Purchasing Health"]);
      } else if (call.entrypoint === "slay_idle_adventurer") {
        setNotification([
          ...notification,
          `You slayed ${
            call.calldata[0] && parseInt(call.calldata[0].toString())
          }`,
        ]);
        setLoadingQuery("adventurerByIdQuery");
        setLoadingMessage([...loadingMessage, "Slaying Adventurer"]);
      }
    }
  }, [calls, items, ownedItems, loadingMessage, notification]);

  useEffect(() => {
    handleLoadData();
  }, [calls, handleLoadData]);

  return (
    <>
      {displayCart ? (
        <div className="absolute right-[50px] w-[300px] h-[400px] sm:right-[280px] top-20 sm:top-32 z-10 sm:w-[400px] sm:h-[400px] p-3 bg-terminal-black border border-terminal-green">
          <p className="text-2xl">TRANSACTIONS</p>
          <div className="w-full border border-terminal-green "></div>
          <div className="flex flex-col h-[200px] overflow-auto">
            {calls.map((call: Call, i: number) => (
              <div key={i}>
                <div className="flex flex-col gap-2">
                  {call && (
                    <div className="flex items-center justify-between text-xs sm:text-base">
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
                const items: string[] = [];

                for (const dict of calls) {
                  if (
                    dict.hasOwnProperty("entrypoint") &&
                    (dict["entrypoint"] === "bid_on_item" ||
                      dict["entrypoint"] === "claim_item")
                  ) {
                    items.push(dict.calldata[0]?.toString() ?? "");
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
                        marketIds: items,
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
