import React, { useState } from "react";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useTransactionManager } from "@starknet-react/core";
import { Button } from "./Button";

const TransactionCart = () => {
  const { writeAsync, addToCalls, calls } = useTransactionCart();
  const { addTransaction } = useTransactionManager();
  const [isOpen, setIsOpen] = useState(false);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  return (
    <>
      <button
        onClick={toggleDropdown}
        className="flex p-2 bg-black border border-terminal-greenrelative"
      >
        {isOpen ? "Hide Cart" : "Show Cart"}
      </button>
      {isOpen ? (
        <div className="absolute right-0 top-10 z-10 w-96 h-96 p-4 m-2 bg-terminal-black border border-terminal-green">
          <h1>TRANSACTIONS</h1>
          <ul>
            {calls.map((call, i) => (
              <li key={i}>
                <div>
                  <p>{call.selector}</p>
                  {/* {call.metadata.method}
                  {call.metadata.description} */}
                </div>
              </li>
            ))}
          </ul>
          <Button
            onClick={async () =>
              await writeAsync().then((tx: any) =>
                addTransaction({
                  hash: tx.transaction_hash,
                  metadata: {
                    method: "Performing multicall",
                    description: "Transactions have been batched and sent!",
                  },
                })
              )
            }
          >
            Submit all Transactions
          </Button>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
