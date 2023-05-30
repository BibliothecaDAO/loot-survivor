import React, { useState, useRef } from "react";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { TxStatus } from "./TxStatus";
import { Metadata } from "../types";
import { Button } from "./Button";
import { padAddress, shortenHex } from "../lib/utils";
import useOnClickOutside from "../hooks/useOnClickOutside";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { processNotification } from "./NotificationDisplay";
import { useQueriesStore } from "../hooks/useQueryStore";

const TransactionHistory = () => {
  const wrapperRef = useRef<HTMLDivElement>(null); // Update the type here
  useOnClickOutside(wrapperRef, () => setIsOpen(false));
  const { adventurer } = useAdventurerStore();

  const { hashes, transactions, addTransaction } = useTransactionManager();
  const [isOpen, setIsOpen] = useState(false);
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });
  const { data: queryData } = useQueriesStore();

  const method = (transactions[0]?.metadata as Metadata)?.method;

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  const history = useLoadingStore((state) => state.history);

  return (
    <div className="relative" ref={wrapperRef}>
      <Button onClick={toggleDropdown}>
        {isOpen ? "Hide Ledger" : "Show Ledger"}
      </Button>
      {isOpen ? (
        transactions ? (
          <div className="absolute sm:right-0 top-12 z-10 w-[650px] h-[250px] p-4 bg-terminal-black border border-terminal-green overflow-x-auto table-scroll">
            <p className="text-2xl">Ledger</p>
            <div className="w-full border border-terminal-green" />
            <ul>
              {transactions
                .slice()
                .reverse()
                .map((tx, i) => {
                  const response = history.find(
                    (response) => response.hash == tx.hash
                  );
                  let notification: React.ReactNode = null;
                  const battles = queryData.battlesByBeastQuery
                    ? queryData.battlesByBeastQuery.battles
                    : [];
                  const beast = queryData.beastByIdQuery
                    ? queryData.beastByIdQuery.beasts[0]
                    : [];
                  if (response) {
                    notification = processNotification(
                      response.type,
                      response.notificationData,
                      adventurer,
                      battles,
                      !!adventurer?.beastId,
                      beast
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
                          <p className="text-lg text-terminal-yellow">
                            {(tx?.metadata as Metadata)?.method}
                          </p>
                          {/* </div> */}
                          <div className="mr-4 text-lg">
                            Hash: {shortenHex(tx.hash)}
                          </div>
                          <TxStatus hash={tx.hash} />
                        </div>
                        {response && notification}
                      </div>
                    </li>
                  );
                })}
            </ul>
          </div>
        ) : (
          <div className="absolute right-0 z-10 border top-10 w-96 h-96 bg-terminal-black border-terminal-green">
            <p className="p-2 text-white">No transactions</p>
          </div>
        )
      ) : null}
    </div>
  );
};

export default TransactionHistory;
