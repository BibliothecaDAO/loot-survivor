import React, { useState } from "react";
import {
  useTransactionManager,
  useTransactions,
  useWaitForTransaction,
} from "@starknet-react/core";
import { TxStatus } from "./TxStatus";

const TransactionHistory = () => {
  const {
    hashes,
    transactions: queuedTransactions,
    addTransaction,
  } = useTransactionManager();
  const [isOpen, setIsOpen] = useState(false);
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

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
        queuedTransactions ? (
          <div className="absolute right-0 top-10 z-10 w-[650px] h-[300px] p-2 bg-terminal-black border border-terminal-green overflow-x-auto">
            <h1>LEDGER</h1>
            <div className="border border-terminal-green w-full" />
            {queuedTransactions.map((tx, i) => (
              <ul>
                <li key={i}>
                  <div className="flex flex-row flex-wrap gap-2">
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

//             {/* {queuedTransactions.map((transaction, i) => (
//               <li key={i}>
//                 <h1>{data. && transaction.hash}</h1>
//                 <h1 className="">{data && data.metadata.method}</h1>
//                 <p className="">{transactions.metadata.message}</p>
//               </li>
//             ))} */}

export default TransactionHistory;
