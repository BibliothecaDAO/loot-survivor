import { create } from "zustand";
import { Metadata, TransactionParams } from "../types";

export interface ManagedTransaction<Metadata extends object> {
  /** The transaction hash. */
  hash: string;
  /** Metadata associated with the transaction. */
  metadata?: Metadata;
}

type TransactionManagerState = {
  transactions: ManagedTransaction<Metadata>[];
  hashes: string[];
  addTransaction: ({ hash, metadata }: TransactionParams) => void;
  removeTransaction: ({ hash }: { hash: string }) => void;
};

const useTransactionManager = create<TransactionManagerState>((set, get) => {
  const addTransaction = ({
    hash,
    metadata,
  }: {
    hash: string;
    metadata?: Metadata;
  }) => {
    set((state) => ({
      transactions: [...state.transactions, { hash, metadata }],
    }));
  };

  const removeTransaction = ({ hash }: { hash: string }) => {
    set((state) => ({
      transactions: state.transactions.filter(
        (transaction: ManagedTransaction<Metadata>) => transaction.hash !== hash
      ),
    }));
  };

  return {
    transactions: [],
    hashes: [],
    addTransaction,
    removeTransaction,
  };
});

export default useTransactionManager;
