import { useWaitForTransaction } from "@starknet-react/core";
import { displayAddress, padAddress } from "../lib/utils";

export interface TxActivityProps {
  hash: string;
}

export const TxActivity = ({ hash }: TxActivityProps) => {
  const { data, status, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  return (
    <>
      {(hash && data?.status != "ACCEPTED_ON_L2") ||
      (hash && data?.status != "ACCEPTED_ON_L1") ? (
        <>
          {(data?.status == "RECEIVED" || data?.status == "PENDING") && (
            <div className="loading-ellipsis">Loading</div>
          )}
          <div className="flex flex-col">
            Hash:{" "}
            <a
              href={`https://testnet.starkscan.co/tx/${padAddress(hash)}`}
              target="_blank"
            >
              {displayAddress(hash)}
            </a>
          </div>
          {data && <div>Status: {data.status}</div>}
        </>
      ) : null}
    </>
  );
};
