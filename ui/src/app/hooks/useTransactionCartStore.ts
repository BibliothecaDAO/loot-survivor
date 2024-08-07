import { create } from "zustand";
import { Call } from "@/app/types";
import { AccountInterface } from "starknet";
import { getMaxFee } from "@/app/lib/constants";
import { Network } from "@/app/hooks/useUIStore";

type TransactionCartState = {
  error: boolean;
  setError: (error: boolean) => void;
  handleSubmitCalls: (
    account: AccountInterface,
    calls: Call[],
    isArcade: boolean,
    ethBalance: number,
    showTopUpDialog: (show: boolean) => void,
    setTopUpAccount: (account: string) => void,
    network: Network
  ) => Promise<any>;
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
    calls: Call[],
    isArcade: boolean,
    ethBalance: number,
    showTopUpDialog: (show: boolean) => void,
    setTopUpAccount: (account: string) => void,
    network: Network
  ) => {
    const maxFee = getMaxFee(network!);
    try {
      let tx;
      if (isArcade) {
        // If they have an arcade account, estimate the max fee
        if (ethBalance < maxFee) {
          showTopUpDialog(true);
          setTopUpAccount(account?.address ?? "");
          throw new Error("Not enough eth for gas.");
        } else {
          tx = await account.execute(calls, {
            maxFee: maxFee,
          });
        }
      } else {
        tx = await account.execute(calls);
      }

      set({ calls: [], error: false });

      return tx;
    } catch (error) {
      setError(true);
      resetCalls();
      if (error instanceof Error) {
        console.log(error);
        throw new Error(error.message);
      } else {
        // Handle non-Error types
        console.log("An error occurred:", error);
      }
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
