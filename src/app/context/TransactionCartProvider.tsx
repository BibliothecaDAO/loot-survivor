import React, { createContext, useContext, useState, useEffect } from "react";
import { useContractWrite } from "@starknet-react/core";

export interface TransactionCartState {
  /** The connected guild object. */
  writeAsync: any;
  calls: any[];
  addToCalls: (value: any) => void;
}

const TRANSACTION_CART_INITIAL_STATE: TransactionCartState = {
  writeAsync: () => undefined,
  calls: [],
  addToCalls: (value: any) => undefined,
};

const TransactionCartContext = createContext<TransactionCartState>(
  TRANSACTION_CART_INITIAL_STATE
);

export function useTransactionCart(): TransactionCartState {
  return useContext(TransactionCartContext);
}

export const useTransactionCartContext = () => {
  const [calls, setCalls] = useState<any>([]);

  const addToCalls = ({ contractAddress, selector, calldata }: any) => {
    console.log("addToCalls", contractAddress, selector, calldata);
    const tx = {
      contractAddress: contractAddress,
      entrypoint: selector,
      calldata: calldata,
    };

    setCalls((calls: any) => [...calls, tx]);
  };

  const { writeAsync } = useContractWrite({ calls });

  return { writeAsync, calls, addToCalls };
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
