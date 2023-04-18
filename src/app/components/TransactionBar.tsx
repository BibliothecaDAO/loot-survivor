import React, { useState } from "react";
import { useTransactionManager, useTransactions } from "@starknet-react/core";

const TransactionBar = () => {
  const { hashes, addTransaction } = useTransactionManager();
  const transactions = useTransactions({ hashes });
  const [isOpen, setIsOpen] = useState(false);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  return (
    <>
      {/* <button onClick={() => addTransaction({ hash: txHash, metadata: { test: true } })}>
        Add transaction
      </button> */}
      <div className="">
        <button
          onClick={toggleDropdown}
          className="flex p-2 bg-black border border-terminal-green"
        >
          {isOpen ? "Hide Transactions" : "Show Transactions"}
        </button>
        {isOpen && (
          <div className="fixed z-10 w-72 h-72 bg-terminal-black border border-terminal-green bottom-0">
            <ul>
              {transactions.map(({ data }, i) => (
                <li key={i}>{data && data.transaction_hash}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </>
  );
};

export default TransactionBar;
