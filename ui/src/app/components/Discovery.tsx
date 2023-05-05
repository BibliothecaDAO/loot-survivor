import { useQueriesStore } from "../hooks/useQueryStore";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import LootIconLoader from "./Loader";

interface DiscoveryProps {
  discoveries: any[];
}

const Discovery = ({ discoveries }: DiscoveryProps) => {
  const isLoading = useQueriesStore((state) => state.isLoading);

  console.log("loading", isLoading)

  return (
    <div className="flex flex-col items-center gap-5 m-auto text-xl">
      {discoveries.length > 0 ? (
        <>
          <h3 className="text-center">Your travels</h3>
          {isLoading.discoveryByTxHashQuery && <LootIconLoader />}
          <div className="flex flex-col items-center gap-2">
            {discoveries.map((discovery: any, index: number) => (
              <DiscoveryDisplay key={index} discoveryData={discovery} />
            ))}
          </div>
        </>
      ) : (
        <p>You have not yet made any discoveries!</p>
      )}
    </div>
  );
};

export default Discovery;
