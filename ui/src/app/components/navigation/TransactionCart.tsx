import React, { useCallback, useEffect, useState } from "react";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import { Button } from "../buttons/Button";
import { MdClose } from "react-icons/md";
import useLoadingStore from "../../hooks/useLoadingStore";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { useQueriesStore, QueryKey } from "../../hooks/useQueryStore";
import {
  processItemName,
  getItemPrice,
  getItemData,
  getValueFromKey,
} from "../../lib/utils";
import useUIStore from "../../hooks/useUIStore";
import { useUiSounds } from "../../hooks/useUiSound";
import { soundSelector } from "../../hooks/useUiSound";
import {
  Item,
  NullItem,
  Call,
  NullAdventurer,
  ItemPurchase,
} from "../../types";
import { GameData } from "../GameData";
import { getKeyFromValue } from "../../lib/utils";

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
  const { addTransaction } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const [notification, setNotification] = useState<string[]>([]);
  const [loadingMessage, setLoadingMessage] = useState<string[]>([]);
  const [loadingQuery, setLoadingQuery] = useState<QueryKey | null>(null);
  const { data } = useQueriesStore();
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const equipItems = useUIStore((state) => state.equipItems);
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const purchaseItems = useUIStore((state) => state.purchaseItems);
  const setPurchaseItems = useUIStore((state) => state.setPurchaseItems);
  const upgradeStats = useUIStore((state) => state.upgradeStats);
  const setUpgradeStats = useUIStore((state) => state.setUpgradeStats);

  const items = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
    : [];

  const ownedItems = data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const gameData = new GameData();

  const handleBuyItem = useCallback(
    (call: any) => {
      const item = items.find(
        (item: Item) =>
          item.item === (Array.isArray(call.calldata) && call.calldata[0])
      );
      const itemName = processItemName(item ?? NullItem);
      const { tier } = getItemData(item?.item ?? "");
      setNotification((notifications) => [
        ...notifications,
        `You purchased ${item?.item && itemName} for ${getItemPrice(
          tier,
          adventurer?.charisma ?? 0
        )} gold`,
      ]);
      setLoadingQuery("latestMarketItemsQuery");
      setLoadingMessage((messages) => [...messages, "Purchasing"]);
    },
    [items]
  );

  const handleEquipItem = () => {
    setNotification((notifications) => [
      ...notifications,
      `You equipped ${equipItems.length} items!`,
    ]);
    setLoadingQuery("adventurerByIdQuery");
    setLoadingMessage((messages) => [...messages, "Equipping"]);
  };

  const handleDropItems = () => {
    setNotification((notifications) => [
      ...notifications,
      `You dropped ${dropItems.length} items!`,
    ]);
    setLoadingQuery("itemsByAdventurerQuery");
    setLoadingMessage((messages) => [...messages, "Dropping"]);
  };

  const handlePurchaseHealth = useCallback((call: any) => {
    setNotification((notifications) => [
      ...notifications,
      `You purchased ${
        Array.isArray(call.calldata) &&
        call.calldata[2] &&
        parseInt(call.calldata[2].toString()) * 10
      } health!`,
    ]);
    setLoadingQuery("adventurerByIdQuery");
    setLoadingMessage((messages) => [...messages, "Purchasing Health"]);
  }, []);

  const handleSlayIdleAdventurer = useCallback((call: any) => {
    setNotification((notifications) => [
      ...notifications,
      `You slayed ${
        Array.isArray(call.calldata) &&
        call.calldata[0] &&
        parseInt(call.calldata[0].toString())
      }`,
    ]);
    setLoadingQuery("adventurerByIdQuery");
    setLoadingMessage((messages) => [...messages, "Slaying Adventurer"]);
  }, []);

  const handleLoadData = useCallback(() => {
    for (let call of calls) {
      switch (call.entrypoint) {
        case "buy_item":
          handleBuyItem(call);
          break;
        case "equip":
          handleEquipItem();
          break;
        case "drop":
          handleDropItems();
          break;
        case "purchase_health":
          handlePurchaseHealth(call);
          break;
        case "slay_idle_adventurer":
          handleSlayIdleAdventurer(call);
          break;
        default:
          break;
      }
    }
  }, [
    calls,
    handleBuyItem,
    handleEquipItem,
    handleDropItems,
    handlePurchaseHealth,
    handleSlayIdleAdventurer,
  ]);

  useEffect(() => {
    handleLoadData();
  }, [calls]);

  const handleResetCalls = () => {
    resetCalls();
    setEquipItems([]);
    setDropItems([]);
    setPurchaseItems([]);
    setUpgradeStats([]);
  };

  return (
    <>
      {displayCart ? (
        <div className="absolute right-[50px] w-[300px] h-[400px] sm:right-[280px] top-20 sm:top-32 z-10 sm:w-[400px] sm:h-[400px] p-3 bg-terminal-black border border-terminal-green">
          <div className="flex flex-row justify-between">
            <p className="text-2xl">TRANSACTIONS</p>
            <button
              onClick={() => {
                setDisplayCart(false);
                clickPlay();
              }}
              className="text-red-500 hover:text-red-700"
            >
              <MdClose size={40} />
            </button>
          </div>
          <div className="w-full border border-terminal-green "></div>
          <div className="flex flex-col h-full overflow-auto">
            {calls.map((call: Call, i: number) => (
              <div key={i}>
                <div className="flex flex-col gap-2">
                  {call && (
                    <div className="flex items-center justify-between text-xs sm:text-base">
                      <p className="uppercase">
                        {call.entrypoint === "buy_items_and_upgrade_stats"
                          ? "Upgrade"
                          : call.entrypoint}
                      </p>
                      {call.entrypoint === "equip" ? (
                        <div className="flex flex-col">
                          {equipItems.map((item: string, index: number) => (
                            <div className="flex flex-row" key={index}>
                              <p>
                                {getValueFromKey(
                                  gameData.ITEMS,
                                  parseInt(item)
                                )}
                              </p>
                              <button
                                onClick={() => {
                                  clickPlay();
                                  const newItems = equipItems.filter(
                                    (i) => i !== item
                                  );
                                  setEquipItems(newItems);
                                  if (newItems.length === 0) {
                                    removeFromCalls(call);
                                  }
                                }}
                                className="text-red-500 hover:text-red-700"
                              >
                                <MdClose size={20} />
                              </button>
                            </div>
                          ))}
                        </div>
                      ) : call.entrypoint === "drop" ? (
                        <div className="flex flex-col">
                          {dropItems.map((item: string, index: number) => (
                            <div className="flex flex-row" key={index}>
                              <p>
                                {`Drop ${getValueFromKey(
                                  gameData.ITEMS,
                                  parseInt(item)
                                )}`}
                              </p>
                              <button
                                onClick={() => {
                                  clickPlay();
                                  const newItems = dropItems.filter(
                                    (i) => i !== item
                                  );
                                  setDropItems(newItems);
                                  if (newItems.length === 0) {
                                    removeFromCalls(call);
                                  }
                                }}
                                className="text-red-500 hover:text-red-700"
                              >
                                <MdClose size={20} />
                              </button>
                            </div>
                          ))}
                        </div>
                      ) : call.entrypoint === "buy_items_and_upgrade_stats" ? (
                        <div className="flex flex-col">
                          {upgradeStats.map((stat: string, index: number) => (
                            <div className="flex flex-row" key={index}>
                              <p>
                                {`Upgrade ${getValueFromKey(
                                  gameData.STATS,
                                  parseInt(stat)
                                )}`}
                              </p>
                              <button
                                onClick={() => {
                                  clickPlay();
                                  const newStats = upgradeStats.filter(
                                    (i) => i !== stat
                                  );
                                  setUpgradeStats(newStats);
                                  if (newStats.length === 0) {
                                    removeFromCalls(call);
                                  }
                                }}
                                className="text-red-500 hover:text-red-700"
                              >
                                <MdClose size={20} />
                              </button>
                            </div>
                          ))}
                          {purchaseItems.map(
                            (item: ItemPurchase, index: number) => (
                              <div className="flex flex-row gap-1" key={index}>
                                <p className="text-sm">
                                  {item.equip === "1"
                                    ? "Buy + Equip"
                                    : "Buy, Don't Equip"}
                                </p>
                                <p className="text-sm">
                                  {getValueFromKey(
                                    gameData.ITEMS,
                                    parseInt(item.item)
                                  )}
                                </p>
                                <button
                                  onClick={() => {
                                    clickPlay();
                                    const newItems = purchaseItems.filter(
                                      (i) => i.item !== item.item
                                    );
                                    setPurchaseItems(newItems);
                                  }}
                                  className="text-red-500 hover:text-red-700"
                                >
                                  <MdClose size={20} />
                                </button>
                              </div>
                            )
                          )}
                        </div>
                      ) : (
                        <p>{call.metadata}</p>
                      )}
                      <button
                        onClick={() => {
                          removeFromCalls(call);
                          clickPlay();
                          if (call.entrypoint === "equip") {
                            setEquipItems([]);
                          }
                          if (call.entrypoint === "drop") {
                            setDropItems([]);
                          }
                          if (
                            call.entrypoint === "buy_items_and_upgrade_stats"
                          ) {
                            setUpgradeStats([]);
                            setPurchaseItems([]);
                          }
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
                    if (Array.isArray(dict.calldata)) {
                      items.push(dict.calldata[0]?.toString() ?? "");
                    }
                  }
                  if (dict["entrypoint"] === "equip") {
                    if (Array.isArray(dict.calldata)) {
                      items.push(dict.calldata[2]?.toString() ?? "");
                    }
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
            <Button onClick={() => handleResetCalls()}>Clear Cart</Button>
          </div>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
