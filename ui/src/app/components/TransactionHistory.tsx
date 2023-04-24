import React, { useState } from "react";
import {
  useTransactionManager,
  useTransactions,
  useWaitForTransaction,
} from "@starknet-react/core";
import { TxStatus } from "./TxStatus";
import { Metadata } from "../types";

const TransactionHistory = () => {
  const { hashes, transactions, addTransaction } = useTransactionManager();
  const [isOpen, setIsOpen] = useState(false);
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const method = (transactions[0]?.metadata as Metadata)?.method;

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  return (
    <div className="relative">
      <button
        onClick={toggleDropdown}
        className="flex p-2 bg-black border border-terminal-green relative"
      >
        {isOpen ? "Hide Ledger" : "Show Ledger"}
      </button>
      {isOpen ? (
        transactions ? (
          <div className="absolute right-0 top-10 z-10 w-[650px] h-[250px] p-2 bg-terminal-black border border-terminal-green overflow-x-auto">
            <p className="text-2xl">LEDGER</p>
            <div className="border border-terminal-green w-full" />
            {transactions
              .slice()
              .reverse()
              .map((tx, i) => (
                <ul key={i}>
                  <li>
                    <div className="flex flex-row flex-wrap gap-1">
                      <p className="text-white text-xl">
                        {(tx?.metadata as Metadata)?.method}:{" "}
                      </p>
                      <p className="text-white text-xl">
                        {(tx?.metadata as Metadata)?.description}
                      </p>
                    </div>
                    <div className="flex flex-row">
                      <div className="mr-4">Hash: {tx.hash}</div>
                      <TxStatus hash={tx.hash} />
                    </div>
                  </li>
                </ul>
              ))}
          </div>
        ) : (
          <div className="absolute right-0 top-10 z-10 w-96 h-96 bg-terminal-black border border-terminal-green">
            <p className="p-2 text-white">No transactions</p>
          </div>
        )
      ) : null}
    </div>
  );
};

export default TransactionHistory;
