import React, {
  useCallback,
  useEffect,
  useState,
  useRef,
  RefObject,
} from "react";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { Button } from "../buttons/Button";
import { MdClose } from "react-icons/md";
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
import { Item, NullItem, Call, ItemPurchase, ZeroUpgrade } from "../../types";
import { GameData } from "../GameData";
import useOnClickOutside from "@/app/hooks/useOnClickOutside";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { chunkArray } from "../../lib/utils";
import { UpgradeStats } from "../../types";
import { useContracts } from "@/app/hooks/useContracts";

export interface TransactionCartProps {
  buttonRef: RefObject<HTMLElement>;
  multicall: (...args: any[]) => any;
}

const TransactionCart = ({ buttonRef, multicall }: TransactionCartProps) => {
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeFromCalls = useTransactionCartStore(
    (state) => state.removeFromCalls
  );
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const resetCalls = useTransactionCartStore((state) => state.resetCalls);
  const [notification, setNotification] = useState<any[]>([]);
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
  const potionAmount = useUIStore((state) => state.potionAmount);
  const setPotionAmount = useUIStore((state) => state.setPotionAmount);
  const purchaseItems = useUIStore((state) => state.purchaseItems);
  const setPurchaseItems = useUIStore((state) => state.setPurchaseItems);
  const upgrades = useUIStore((state) => state.upgrades);
  const setUpgrades = useUIStore((state) => state.setUpgrades);
  const setUpgradeScreen = useUIStore((state) => state.setUpgradeScreen);
  const slayAdventurers = useUIStore((state) => state.slayAdventurers);
  const setSlayAdventurers = useUIStore((state) => state.setSlayAdventurers);
  const wrapperRef = useRef<HTMLDivElement>(null);
  useOnClickOutside(wrapperRef, () => setDisplayCart(false), buttonRef);
  const resetNotification = useLoadingStore((state) => state.resetNotification);

  const items = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
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
      setLoadingMessage((messages) => [...messages, "Purchasing"]);
    },
    [items]
  );

  const handleEquipItem = () => {
    setNotification((notifications) => [
      ...notifications,
      `You equipped ${equipItems.length} items!`,
    ]);
    setLoadingMessage((messages) => [...messages, "Equipping"]);
  };

  const handleDropItems = () => {
    setNotification((notifications) => [
      ...notifications,
      `You dropped ${dropItems.length} items!`,
    ]);
    setLoadingMessage((messages) => [...messages, "Dropping"]);
  };

  const handleUpgradeAdventurer = () => {
    setNotification((notifications) => [
      ...notifications,
      {
        Stats: upgrades,
        Items: purchaseItems,
        Potions: potionAmount,
      },
    ]);
    setLoadingMessage((messages) => [...messages, "Upgrading"]);
  };

  const handleSlayIdleAdventurers = useCallback((call: any) => {
    setNotification((notifications) => [
      ...notifications,
      `You slayed ${
        Array.isArray(call.calldata) && call.calldata[0]
      } Adventurers`,
    ]);
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
        case "upgrade":
          handleUpgradeAdventurer();
          break;
        case "slay_idle_adventurers":
          handleSlayIdleAdventurers(call);
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
    handleUpgradeAdventurer,
    handleSlayIdleAdventurers,
  ]);

  useEffect(() => {
    handleLoadData();
  }, [calls]);

  const handleResetCalls = () => {
    resetCalls();
    setEquipItems([]);
    setDropItems([]);
    setPotionAmount(0);
    setPurchaseItems([]);
    setUpgrades({ ...ZeroUpgrade });
    setSlayAdventurers([]);
  };

  const handleAddUpgradeTx = (
    currentUpgrades?: UpgradeStats,
    potions?: number,
    items?: any[]
  ) => {
    removeEntrypointFromCalls("upgrade");
    const upgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "upgrade",
      calldata: [
        adventurer?.id?.toString() ?? "",
        potions! >= 0 ? potions?.toString() : potionAmount.toString(),
        currentUpgrades
          ? currentUpgrades["Strength"].toString()
          : upgrades["Strength"].toString(),
        currentUpgrades
          ? currentUpgrades["Dexterity"].toString()
          : upgrades["Dexterity"].toString(),
        currentUpgrades
          ? currentUpgrades["Vitality"].toString()
          : upgrades["Vitality"].toString(),
        currentUpgrades
          ? currentUpgrades["Intelligence"].toString()
          : upgrades["Intelligence"].toString(),
        currentUpgrades
          ? currentUpgrades["Wisdom"].toString()
          : upgrades["Wisdom"].toString(),
        currentUpgrades
          ? currentUpgrades["Charisma"].toString()
          : upgrades["Charisma"].toString(),
        "0",
        items ? items.length.toString() : purchaseItems.length.toString(),
        ...(items
          ? items.flatMap(Object.values)
          : purchaseItems.flatMap(Object.values)),
      ],
    };
    addToCalls(upgradeTx);
  };

  const filteredStats = Object.entries(upgrades).filter(
    (stat: any) => stat[1] !== 0
  );

  const formattedSlayedAdventurers = chunkArray(slayAdventurers, 2);

  return (
    <>
      {displayCart ? (
        <div
          ref={wrapperRef}
          className="absolute right-[50px] w-[300px] h-[400px] sm:right-[280px] top-20 sm:top-32 z-10 sm:w-[400px] sm:h-[400px] p-3 bg-terminal-black border border-terminal-green"
        >
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
                      ) : call.entrypoint === "upgrade" ? (
                        <div className="flex flex-col">
                          {filteredStats.map(
                            ([string, number], index: number) => (
                              <div className="flex flex-row" key={index}>
                                <p>{`Upgrade ${string} x ${number}`}</p>
                                <button
                                  onClick={() => {
                                    clickPlay();
                                    upgrades[string] = 0;
                                    setUpgrades(upgrades);
                                    const newStats = Object.entries(
                                      upgrades
                                    ).filter((stat: any) => stat[1] !== 0);
                                    if (newStats.length === 0) {
                                      removeFromCalls(call);
                                    }
                                  }}
                                  className="text-red-500 hover:text-red-700"
                                >
                                  <MdClose size={20} />
                                </button>
                              </div>
                            )
                          )}
                          {potionAmount !== 0 && (
                            <div className="flex flex-row">
                              <p>
                                Purchase {potionAmount} Potion
                                {potionAmount > 1 ? "s" : ""}
                              </p>
                              <button
                                onClick={() => {
                                  clickPlay();
                                  setPotionAmount(0);
                                  handleAddUpgradeTx(undefined, 0, undefined);
                                }}
                                className="text-red-500 hover:text-red-700"
                              >
                                <MdClose size={20} />
                              </button>
                            </div>
                          )}
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
                                    handleAddUpgradeTx(
                                      undefined,
                                      undefined,
                                      newItems
                                    );
                                  }}
                                  className="text-red-500 hover:text-red-700"
                                >
                                  <MdClose size={20} />
                                </button>
                              </div>
                            )
                          )}
                        </div>
                      ) : call.entrypoint === "slay_idle_adventurers" ? (
                        <div className="flex flex-col">
                          {formattedSlayedAdventurers.map(
                            (adventurer: string[], index: number) => (
                              <div className="flex flex-row gap-1" key={index}>
                                <p className="text-sm">Slay {adventurer[0]}</p>
                                <button
                                  onClick={() => {
                                    clickPlay();
                                    const newSlayAdventurers =
                                      formattedSlayedAdventurers.filter(
                                        (adv) => adv[0] !== adventurer[0]
                                      );
                                    setSlayAdventurers(
                                      newSlayAdventurers.flat()
                                    );
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
                          if (call.entrypoint === "upgrade") {
                            setUpgrades({ ...ZeroUpgrade });
                            setPurchaseItems([]);
                          }
                          if (call.entrypoint === "slay_idle_adventurers") {
                            setSlayAdventurers([]);
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
                resetNotification();
                await multicall(loadingMessage, loadingQuery, notification);
                handleResetCalls();
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
