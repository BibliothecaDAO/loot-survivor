import { create } from "zustand";

interface Call {
  contractAddress: string;
  entrypoint: string;
  calldata: Array<string | number | undefined>;
  metadata?: any;
}

type TransactionCartState = {
  handleSubmitCalls: (writeAsync: () => Promise<any>) => Promise<any>;
  calls: Call[];
  addToCalls: (value: Call) => void;
  removeFromCalls: (value: Call) => void;
};

const useTransactionCartStore = create<TransactionCartState>((set, get) => {
  const addToCalls = (tx: Call) => {
    set((state) => ({ calls: [...state.calls, tx] }));
  };

  const removeFromCalls = (tx: Call) => {
    set((state) => ({
      calls: state.calls.filter(
        (call: any) =>
          call.entrypoint !== tx.entrypoint ||
          call.calldata !== tx.calldata ||
          call.metadata !== tx.metadata
      ),
    }));
  };

  const handleSubmitCalls = async (writeAsync: () => Promise<any>) => {
    try {
      const tx = await writeAsync();
      set({ calls: [] });
      return tx;
    } catch (error) {
      console.log(error);
      set({ calls: [] });
    }
  };

  const resetCalls = () => {
    set({ calls: [] });
  };

  return {
    handleSubmitCalls,
    calls: [],
    addToCalls,
    removeFromCalls,
    resetCalls,
  };
});

export default useTransactionCartStore;
