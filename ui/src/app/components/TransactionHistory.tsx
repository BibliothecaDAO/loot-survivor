import React, { useState } from "react";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { TxStatus } from "./TxStatus";
import { Metadata } from "../types";
import { Button } from "./Button";

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
      <Button
        onClick={toggleDropdown}

      >
        {isOpen ? "Hide Ledger" : "Show Ledger"}
      </Button>
      {isOpen ? (
        transactions ? (
          <div className="absolute right-0 top-10 z-10 w-[650px] h-[250px] p-2 bg-terminal-black border border-terminal-green overflow-x-auto">
            <p className="text-2xl">LEDGER</p>
            <div className="w-full border border-terminal-green" />
            <ul>
              {transactions
                .slice()
                .reverse()
                .map((tx, i) => (
                  <li key={i}>
                    <div className="flex flex-row flex-wrap gap-1">
                      <p className="text-xl text-white">
                        {(tx?.metadata as Metadata)?.method}:{" "}
                      </p>
                      <p className="text-xl text-white">
                        {(tx?.metadata as Metadata)?.description}
                      </p>
                    </div>
                    <div className="flex flex-row">
                      <div className="mr-4">Hash: {tx.hash}</div>
                      <TxStatus hash={tx.hash} />
                    </div>
                  </li>
                ))}
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
