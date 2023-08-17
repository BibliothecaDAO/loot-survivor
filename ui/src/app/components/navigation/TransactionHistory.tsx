import React, { useState, useRef, RefObject } from "react";
import { useTransactionManager } from "@starknet-react/core";
import { TxStatus } from "./TxStatus";
import { Metadata, NullAdventurer, Notification } from "../../types";
import { padAddress, shortenHex } from "../../lib/utils";
import useOnClickOutside from "../../hooks/useOnClickOutside";
import useLoadingStore from "../../hooks/useLoadingStore";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { processNotifications } from "../notifications/NotificationHandler";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useUIStore from "../../hooks/useUIStore";
import { MdClose } from "react-icons/md";
import { useUiSounds } from "../../hooks/useUiSound";
import { soundSelector } from "../../hooks/useUiSound";

export interface TransactionHistoryProps {
  buttonRef: RefObject<HTMLElement>;
}

const TransactionHistory = ({ buttonRef }: TransactionHistoryProps) => {
  const wrapperRef = useRef<HTMLDivElement>(null);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  useOnClickOutside(wrapperRef, () => setDisplayHistory(false), buttonRef);
  const { adventurer } = useAdventurerStore();

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const { transactions } = useTransactionManager();
  const { data: queryData } = useQueriesStore();
  const displayHistory = useUIStore((state) => state.displayHistory);
  const { play } = useUiSounds(soundSelector.click);

  const history = useLoadingStore((state) => state.history);

  return (
    <>
      {displayHistory ? (
        transactions ? (
          <div
            ref={wrapperRef}
            className="absolute m-auto z-10 right-[50px] w-[300px] h-[400px] sm:right-16 top-20 sm:top-32 w-1/4 sm:w-[650px] h-3/4 p-4 bg-terminal-black border border-terminal-green overflow-y-auto"
          >
            <div className="flex flex-row justify-between">
              <p className="text-2xl">Ledger</p>
              <button
                onClick={() => {
                  setDisplayHistory(false);
                  play();
                }}
                className="text-red-500 hover:text-red-700"
              >
                <MdClose size={40} />
              </button>
            </div>
            <div className="w-full border border-terminal-green" />
            <div className="overflow-y-auto">
              <ul>
                {transactions
                  .slice()
                  .reverse()
                  .map((tx, i) => {
                    const response = history.find(
                      (response) => response.hash == tx.hash
                    );
                    const method = (tx?.metadata as Metadata)?.method;
                    let notifications: Notification[] = [];
                    const battles = queryData.battlesByBeastQuery
                      ? queryData.battlesByBeastQuery.battles
                      : [];
                    if (response) {
                      notifications = processNotifications(
                        response.type,
                        response.notificationData,
                        battles,
                        hasBeast,
                        adventurer ?? NullAdventurer
                      );
                    }
                    return (
                      <li
                        key={i}
                        className="p-1 m-1 border border-terminal-green"
                      >
                        <div className="flex flex-col">
                          <div className="flex flex-row justify-between border-b border-terminal-green">
                            {/* <div className="flex flex-wrap gap-1"> */}
                            <p className="text-xs sm:text-lg text-terminal-yellow">
                              {method}
                            </p>
                            {/* </div> */}
                            <div className="mr-4 text-xs sm:text-lg">
                              <span className="hidden sm:block">Hash:</span>
                              <a
                                href={`https://goerli.voyager.online/tx/${padAddress(
                                  tx.hash
                                )}`}
                                target="_blank"
                              >
                                {shortenHex(tx.hash)}
                              </a>
                            </div>
                            <TxStatus hash={tx.hash} />
                          </div>
                          {response &&
                            notifications.map(
                              (notification) => notification.message
                            )}
                        </div>
                      </li>
                    );
                  })}
              </ul>
            </div>
          </div>
        ) : (
          <div className="absolute right-0 z-10 border top-10 w-96 h-96 bg-terminal-black border-terminal-green">
            <p className="p-2 text-white">No transactions</p>
          </div>
        )
      ) : null}
    </>
  );
};

export default TransactionHistory;
