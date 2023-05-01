import React, { createContext, useContext, useState, useEffect } from "react";
import { useContractWrite } from "@starknet-react/core";

export interface TransactionCartState {
  /** The connected guild object. */
  handleSubmitCalls: any;
  calls: any[];
  addToCalls: (value: any) => void;
  removeFromCalls: (value: any) => void;
}

const TRANSACTION_CART_INITIAL_STATE: TransactionCartState = {
  handleSubmitCalls: () => undefined,
  calls: [],
  addToCalls: (value: any) => undefined,
  removeFromCalls: (value: any) => undefined,
};

const TransactionCartContext = createContext<TransactionCartState>(
  TRANSACTION_CART_INITIAL_STATE
);

export function useTransactionCart(): TransactionCartState {
  return useContext(TransactionCartContext);
}

export const useTransactionCartContext = () => {
  const [calls, setCalls] = useState<any>([]);

  const addToCalls = ({
    contractAddress,
    selector,
    calldata,
    metadata,
  }: any) => {
    const tx = {
      contractAddress: contractAddress,
      entrypoint: selector,
      calldata: calldata,
      metadata: metadata,
    };

    setCalls((calls: any) => [...calls, tx]);
  };

  const removeFromCalls = ({
    selector,
    calldata,
    metadata,
  }: {
    selector: string;
    calldata: string;
    metadata: any;
  }) => {
    setCalls((calls: any) =>
      calls.filter(
        (call: any) =>
          call.entrypoint !== selector ||
          call.calldata !== calldata ||
          call.metadata !== metadata
      )
    );
  };

  // useEffect(() => {}, []);

  const { writeAsync } = useContractWrite({ calls });

  const handleSubmitCalls = async () => {
    const tx = await writeAsync();
    setCalls([]);
    return tx;
  };

  return { handleSubmitCalls, calls, addToCalls, removeFromCalls };
};

export function TransactionCartProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const state = useTransactionCartContext();
  return (
    <TransactionCartContext.Provider value={state}>
      {children}
    </TransactionCartContext.Provider>
  );
}
