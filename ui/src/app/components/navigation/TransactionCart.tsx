import React, { useRef, RefObject } from "react";
import { MdClose } from "react-icons/md";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Button } from "@/app/components/buttons/Button";
import { getValueFromKey } from "@/app/lib/utils";
import useUIStore from "@/app/hooks/useUIStore";
import { useUiSounds } from "@/app/hooks/useUiSound";
import { soundSelector } from "@/app/hooks/useUiSound";
import { Call, ItemPurchase, ZeroUpgrade } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";
import useOnClickOutside from "@/app/hooks/useOnClickOutside";
import { UpgradeStats } from "@/app/types";

export interface TransactionCartProps {
  buttonRef: RefObject<HTMLElement>;
  handleSubmitMulticall: () => void;
  handleAddUpgradeTx: (
    upgrade?: UpgradeStats,
    potionAmount?: number,
    purchaseItems?: ItemPurchase[]
  ) => void;
  handleResetCalls: () => void;
}

const TransactionCart = ({
  buttonRef,
  handleSubmitMulticall,
  handleAddUpgradeTx,
  handleResetCalls,
}: TransactionCartProps) => {
  const calls = useTransactionCartStore((state) => state.calls);
  const removeFromCalls = useTransactionCartStore(
    (state) => state.removeFromCalls
  );
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
  const slayAdventurers = useUIStore((state) => state.slayAdventurers);
  const setSlayAdventurers = useUIStore((state) => state.setSlayAdventurers);
  const wrapperRef = useRef<HTMLDivElement>(null);
  useOnClickOutside(wrapperRef, () => setDisplayCart(false), buttonRef);

  const callExists = calls.length > 0;

  const gameData = new GameData();

  const filteredStats = Object.entries(upgrades).filter(
    (stat: any) => stat[1] !== 0
  );

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
                          {slayAdventurers.map((id: string, index: number) => (
                            <div className="flex flex-row gap-1" key={index}>
                              <p className="text-sm">Slay {id}</p>
                              <button
                                onClick={() => {
                                  clickPlay();
                                  const newSlayAdventurers =
                                    slayAdventurers.filter((adv) => adv !== id);
                                  setSlayAdventurers(newSlayAdventurers);
                                }}
                                className="text-red-500 hover:text-red-700"
                              >
                                <MdClose size={20} />
                              </button>
                            </div>
                          ))}
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
              disabled={!callExists}
              onClick={async () => {
                handleSubmitMulticall();
              }}
            >
              Submit all Transactions
            </Button>
            <Button disabled={!callExists} onClick={() => handleResetCalls()}>
              Clear Cart
            </Button>
          </div>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
