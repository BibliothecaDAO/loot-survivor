import { create } from "zustand";
import { Call } from "@/app/types";
import { AccountInterface } from "starknet";
import { MAX_FEE } from "../lib/constants";

type TransactionCartState = {
  error: boolean;
  setError: (error: boolean) => void;
  handleSubmitCalls: (account: AccountInterface, calls: Call[]) => Promise<any>;
  calls: Call[];
  addToCalls: (value: Call) => void;
  removeFromCalls: (value: Call) => void;
  removeEntrypointFromCalls: (value: string) => void;
  resetCalls: () => void;
};

const useTransactionCartStore = create<TransactionCartState>((set) => {
  const setError = (error: boolean) => set({ error });

  const addToCalls = (tx: Call) => {
    set((state) => ({ calls: [...state.calls, tx] }));
  };

  const removeFromCalls = (tx: Call) => {
    set((state) => ({
      calls: state.calls.filter(
        (call: Call) =>
          call.entrypoint !== tx.entrypoint ||
          call.calldata !== tx.calldata ||
          call.metadata !== tx.metadata
      ),
    }));
  };

  const removeEntrypointFromCalls = (entrypoint: string) => {
    set((state) => ({
      calls: state.calls.filter((call: Call) => call.entrypoint !== entrypoint),
    }));
  };

  const handleSubmitCalls = async (
    account: AccountInterface,
    calls: Call[]
  ) => {
    try {
      const tx = await account.execute(calls, undefined, {
        maxFee: MAX_FEE,
      });
      set({ calls: [], error: false });
      return tx;
    } catch (error) {
      setError(true);
      resetCalls();
    }
  };

  const resetCalls = () => {
    set({ calls: [] });
  };

  return {
    error: false,
    setError,
    handleSubmitCalls,
    calls: [],
    addToCalls,
    removeFromCalls,
    removeEntrypointFromCalls,
    resetCalls,
  };
});

export default useTransactionCartStore;
