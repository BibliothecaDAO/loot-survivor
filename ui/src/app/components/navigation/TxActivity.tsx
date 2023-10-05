import { useEffect, useState } from "react";
import { useWaitForTransaction } from "@starknet-react/core";
import { displayAddress, padAddress } from "../../lib/utils";
import useLoadingStore from "../../hooks/useLoadingStore";
import LootIconLoader from "../icons/Loader";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { InvokeTransactionReceiptResponse } from "starknet";

export const TxActivity = () => {
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const loading = useLoadingStore((state) => state.loading);
  const hash = useLoadingStore((state) => state.hash);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const setTxAccepted = useLoadingStore((state) => state.setTxAccepted);
  const error = useTransactionCartStore((state) => state.error);
  const setError = useTransactionCartStore((state) => state.setError);
  const { data } = useWaitForTransaction({
    hash,
    watch: true,
    onAcceptedOnL2: () => {
      setTxAccepted(true);
    },
    onRejected: () => {
      stopLoading("Rejected");
    },
  }) as { data: InvokeTransactionReceiptResponse };
  const pendingArray = Array.isArray(pendingMessage);
  const [messageIndex, setMessageIndex] = useState(0);

  // stop loading when an error is caught
  useEffect(() => {
    if (error === true) {
      stopLoading(undefined);
      setError(false); // reset the error state
    }
  }, [error, setError, stopLoading]);

  useEffect(() => {
    if (pendingArray) {
      const interval = setInterval(() => {
        setMessageIndex((prevIndex) => (prevIndex + 1) % pendingMessage.length);
      }, 2000);
      return () => clearInterval(interval); // This is important, it will clear the interval when the component is unmounted.
    }
  }, [pendingMessage, messageIndex, pendingArray]);

  return (
    <>
      {loading ? (
        <div className="flex flex-row absolute sm:top-0 sm:relative items-center gap-5 justify-between text-xs sm:text-base p-2 sm:p-0 w-full bg-terminal-black sm:bg-transparent z-40">
          {hash && (
            <div className="flex flex-row gap-2">
              <span className="hidden sm:block">Hash:</span>
              <a
                href={`https://goerli.voyager.online/tx/${padAddress(hash)}`}
                target="_blank"
                className="animate-pulse"
              >
                {displayAddress(hash)}
              </a>
            </div>
          )}
          <div className="flex flex-row items-center w-40 sm:w-48 loading-ellipsis">
            <div className="sm:hidden">
              <LootIconLoader className="self-center mr-3" size={"w-4"} />
            </div>
            <div className="hidden sm:block">
              <LootIconLoader className="self-center mr-3" size={"w-5"} />
            </div>
            {hash
              ? pendingArray
                ? (pendingMessage as string[])[messageIndex]
                : pendingMessage
              : "Confirming Tx"}
          </div>
          {hash && (
            <div className="flex flex-row gap-2">
              <span className="hidden sm:block">Status:</span>{" "}
              {data?.finality_status ?? "PENDING"}
            </div>
          )}
        </div>
      ) : null}
    </>
  );
};
