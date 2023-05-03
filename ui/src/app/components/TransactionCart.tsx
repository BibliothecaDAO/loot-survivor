import React, { useState } from "react";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import {
  useTransactionManager,
  useWaitForTransaction,
  useContractWrite,
} from "@starknet-react/core";
import { Metadata } from "../types";
import { Button } from "./Button";
import { MdClose } from "react-icons/md";
import useLoadingStore from "../hooks/useLoadingStore";

const TransactionCart: React.FC = () => {
  const calls = useTransactionCartStore((state) => state.calls);
  const removeFromCalls = useTransactionCartStore(
    (state) => state.removeFromCalls
  );
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const {
    hashes,
    transactions: queuedTransactions,
    addTransaction,
  } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const [isOpen, setIsOpen] = useState(false);

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
            {calls.map((call: any, i: number) => (
              <div key={i}>
                <div className="flex flex-col gap-2">
                  {call && (
                    <div className="flex items-center justify-between">
                      <p>{call.entrypoint}</p>
                      {/* <p>{call.calldata}</p> */}
                      <p>{call.metadata}</p>
                      <button
                        onClick={() => removeFromCalls(call)}
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
                await handleSubmitCalls(writeAsync).then((tx: any) => {
                  if (tx) {
                    startLoading(
                      "Multicall",
                      tx?.transaction_hash,
                      "Muticalling",
                      "",
                      `Multicall complete!`
                    );
                    const marketIds = [];

                    for (const dict of calls) {
                      if (
                        dict.hasOwnProperty("entrypoint") &&
                        dict["entrypoint"] === "bid_on_item"
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
                  }
                })
              }
              className="absolute bottom-4"
            >
              Submit all Transactions
            </Button>
          </div>
        </div>
      ) : null}
    </>
  );
};

export default TransactionCart;
