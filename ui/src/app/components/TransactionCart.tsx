import React, { useState } from "react";
import { useTransactionCart } from "../context/TransactionCartProvider";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import { Metadata } from "../types";
import { Button } from "./Button";
import { MdClose } from "react-icons/md";

const TransactionCart = () => {
  const { handleSubmitCalls, calls, addToCalls, removeFromCalls } =
    useTransactionCart();
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

  const txLoading = data?.status == "RECEIVED" || data?.status == "PENDING";

  const method = (queuedTransactions[0]?.metadata as Metadata)?.method;

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  // const reorderCards = useCallback((dragIndex: number, hoverIndex: number) => {
  //   txQueue.reorderQueue(dragIndex, hoverIndex);
  // }, []);

  return (
    <>
      <button
        onClick={toggleDropdown}
        className="flex p-2 bg-black border border-terminal-green relative"
      >
        {isOpen ? "Hide Cart" : "Show Cart"}
      </button>
      {isOpen ? (
        <div className="absolute right-[280px] top-20 z-10 w-[400px] h-[400px] p-3 bg-terminal-black border border-terminal-green">
          <p className="text-2xl">TRANSACTIONS</p>
          <div className="w-full border border-terminal-green "></div>
          <div className="flex flex-col h-[200px] overflow-auto">
            {calls.map((call, i) => (
              <div key={i}>
                <div className="flex flex-col gap-2">
                  {call && (
                    <div className="flex items-center justify-between">
                      <p>{call.entrypoint}</p>
                      {/* <p>{call.calldata}</p> */}
                      <p>{call.metadata}</p>
                      <button
                        onClick={() =>
                          removeFromCalls({
                            selector: call.entrypoint,
                            calldata: call.calldata,
                            metadata: call.metadata,
                          })
                        }
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
          <div className="m-2">
            <Button
              onClick={async () =>
                await handleSubmitCalls().then((tx: any) => {
                  setHash(tx.transaction_hash);
                  const marketIds = [];

                  for (const dict of calls) {
                    if (
                      dict.hasOwnProperty("selector") &&
                      dict["selector"] === "bid_on_item"
                    ) {
                      marketIds.push(dict.calldata[0]);
                    }
                  }

                  addTransaction({
                    hash: tx.transaction_hash,
                    metadata: {
                      method: "Performing multicall",
                      description: "Transactions have been batched and sent!",
                      marketIds: marketIds,
                    },
                  });
                })
              }
              className="absolute bottom-4"
            >
              Submit all Transactions
            </Button>
          </div>
          <>
            {txLoading && hash && (
              <div className="loading-ellipsis">Loading</div>
            )}
            {hash && <div className="flex flex-col">Hash: {hash[-1]}</div>}
            {error && <div>Error: {JSON.stringify(error)}</div>}
            {data && <div>Status: {data.status}</div>}
          </>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
