import { useWaitForTransaction } from "@starknet-react/core";

interface TxStatusProps {
  hash: any;
}

export const TxStatus = ({ hash }: TxStatusProps) => {
  const { data } = useWaitForTransaction({ hash });

  return <p className="text-xs sm:text-lg">Status: {data?.status}</p>;
};
