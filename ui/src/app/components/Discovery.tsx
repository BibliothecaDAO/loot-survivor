import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "./Button";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import LootIconLoader from "./Loader";
import { useMediaQuery } from "react-responsive";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useLoadingStore from "../hooks/useLoadingStore";
import { useContracts } from "../hooks/useContracts";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";

interface DiscoveryProps {
  discoveries: any[];
  beasts: any[];
}

const Discovery = ({ discoveries, beasts }: DiscoveryProps) => {
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { adventurerContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { addTransaction } = useTransactionManager();
  const { writeAsync } = useContractWrite({ calls });
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);

  const isLoading = useQueriesStore((state) => state.isLoading);
  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const exploreTx = {
    contractAddress: adventurerContract?.address ?? "",
    entrypoint: "explore",
    calldata: [adventurer?.id ?? "", "0"],
  };

  return (
    <div className="flex flex-col gap-5 items-center">
      <div className="flex flex-col items-center gap-5 m-auto text-xl">
        {discoveries.length > 0 ? (
          <>
            <h3 className="text-center">Your travels</h3>
            {isLoading.discoveryByTxHashQuery && <LootIconLoader />}
            <div className="flex flex-col items-center gap-2 overflow-auto">
              {discoveries.map((discovery: any, index: number) => (
                <div
                  className="w-full p-2 text-left border border-terminal-green text-sm sm:text-base"
                  key={index}
                >
                  <DiscoveryDisplay discoveryData={discovery} beasts={beasts} />
                </div>
              ))}
            </div>
          </>
        ) : (
          <p>You have not yet made any discoveries!</p>
        )}
      </div>
      {isMobileDevice && (
        <Button
          className="w-1/2 text-lg"
          onClick={async () => {
            addToCalls(exploreTx);
            startLoading(
              "Explore",
              "Exploring",
              "discoveryByTxHashQuery",
              adventurer?.id
            );
            await handleSubmitCalls(writeAsync).then((tx: any) => {
              if (tx) {
                setTxHash(tx.transaction_hash);
                addTransaction({
                  hash: tx.transaction_hash,
                  metadata: {
                    method: `Explore with ${adventurer?.name}`,
                  },
                });
              }
            });
          }}
        >
          Explore
        </Button>
      )}
    </div>
  );
};

export default Discovery;
