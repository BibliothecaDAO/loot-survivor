import { useWaitForTransaction } from "@starknet-react/core";
import { displayAddress, padAddress } from "../lib/utils";
import useLoadingStore from "../hooks/useLoadingStore";

export interface TxActivityProps {
  hash: string | undefined;
}

export const TxActivity = () => {
  const loading = useLoadingStore((state) => state.loading);
  const hash = useLoadingStore((state) => state.hash);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const type = useLoadingStore((state) => state.type);
  const { data } = useWaitForTransaction({
    hash,
    watch: true,
  });

  return (
    <>
      {type != "Multicall" ? (
        loading && hash ? (
          <div className="flex flex-row items-center p-4 gap-5">
            {data?.status == "RECEIVED" || data?.status == "PENDING" ? (
              <div className="loading-ellipsis w-48">{pendingMessage}</div>
            ) : (
              <div className="loading-ellipsis">Refreshing data</div>
            )}
            <div className="flex flex-row gap-2">
              Hash:{" "}
              <a
                href={`https://testnet.starkscan.co/tx/${padAddress(hash)}`}
                target="_blank"
                className="animate-pulse"
              >
                {displayAddress(hash)}
              </a>
            </div>
            {data && <div>Status: {data.status}</div>}
          </div>
        ) : null
      ) : (
        (data?.status == "RECEIVED" || data?.status == "PENDING") && (
          <>
            <div className="loading-ellipsis w-48">{pendingMessage}</div>
            <div className="flex flex-row gap-2">
              Hash:{" "}
              <a
                href={`https://testnet.starkscan.co/tx/${padAddress(hash)}`}
                target="_blank"
                className="animate-pulse"
              >
                {displayAddress(hash)}
              </a>
            </div>
            {data && <div>Status: {data.status}</div>}
          </>
        )
      )}
    </>
  );
};
