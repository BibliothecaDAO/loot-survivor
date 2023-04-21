import React, { useState } from "react";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useTransactionManager } from "@starknet-react/core";
import { Button } from "./Button";

const TransactionCart = () => {
  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { addTransaction } = useTransactionManager();
  const [isOpen, setIsOpen] = useState(false);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  console.log(calls);

  return (
    <>
      <button
        onClick={toggleDropdown}
        className="flex p-2 bg-black border border-terminal-green relative"
      >
        {isOpen ? "Hide Cart" : "Show Cart"}
      </button>
      {isOpen ? (
        <div className="absolute right-0 top-10 z-10 w-96 h-96 p-4 m-2 bg-terminal-black border border-terminal-green">
          <h1>TRANSACTIONS</h1>
          <div className="flex flex-row w-full border border-terminal-green">
            {calls.map((call, i) => (
              <li key={i}>
                <div className="flex flex-row gap-2">
                  <>
                    {call && <div>{call.selector}</div>}
                    {call && <div>{call.metadata.method}</div>}
                    {call && <div>{call.metadata.description}</div>}
                  </>
                </div>
              </li>
            ))}
          </div>
          <Button
            onClick={async () =>
              await handleSubmitCalls().then((tx: any) =>
                addTransaction({
                  hash: tx.hash,
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
