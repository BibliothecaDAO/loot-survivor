import { useWaitForTransaction } from "@starknet-react/core";

interface TxStatusProps {
  hash: string;
}

export const TxStatus = ({ hash }: TxStatusProps) => {
  const { data } = useWaitForTransaction({ hash });

  return <p className="text-xs sm:text-lg">Status: {data?.status}</p>;
};
