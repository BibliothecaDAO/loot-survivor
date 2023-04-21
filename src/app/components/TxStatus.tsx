import { useWaitForTransaction } from "@starknet-react/core";

interface TxStatusProps {
  hash: any;
}

export const TxStatus = ({ hash }: TxStatusProps) => {
  const { data, status } = useWaitForTransaction({ hash });

  return <p>Status: {data?.status}</p>;
};
