import React, { useState } from "react";
import {
  useTransactionManager,
  useTransactions,
  useWaitForTransaction,
} from "@starknet-react/core";

const TransactionHistory = () => {
  const {
    hashes,
    transactions: queuedTransactions,
    addTransaction,
  } = useTransactionManager();
  const transactions = useTransactions({ hashes });
  const [isOpen, setIsOpen] = useState(false);
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  const hasTransactions = transactions.length > 0;

  return (
    <div className="relative">
      <button
        onClick={toggleDropdown}
        className="flex p-2 bg-black border border-terminal-green relative"
      >
        {isOpen ? "Hide Transactions" : "Show Transactions"}
        {/* {hasActiveTransactions && (
          <span className="absolute top-0 right-0 text-xs bg-red-500 text-white rounded-full w-4 h-4 flex items-center justify-center">
            1
          </span> */}
      </button>
      {isOpen ? (
        hasTransactions ? (
          <div className="absolute right-0 top-10 z-10 w-96 h-96 p-2 bg-terminal-black border border-terminal-green">
            <h1>TRANSACTIONS</h1>
            <ul>
              {transactions.map(({ data, status }, i) => (
                <li key={i}>
                  <h1>{data && data.transaction_hash}</h1>
                  <div className="flex flex-row gap-2">
                    <>
                      {data?.transaction_hash && (
                        <div>Hash: {data?.transaction_hash}</div>
                      )}
                      {isLoading && hash && (
                        <div className="loading-ellipsis">Loading</div>
                      )}
                      {error && <div>Error: {JSON.stringify(error)}</div>}
                      {data && <div>Status: {status}</div>}
                    </>
                  </div>
                </li>
              ))}
            </ul>
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
