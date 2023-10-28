import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { DiscoveryDisplay } from "@/app/components/actions/DiscoveryDisplay";
import LootIconLoader from "@/app/components/icons/Loader";
import { Discovery } from "@/app/types";

interface DiscoveryProps {
  discoveries: Discovery[];
}

const Discovery = ({ discoveries }: DiscoveryProps) => {
  const isLoading = useQueriesStore((state) => state.isLoading);

  const limitedDiscoveries = discoveries.slice(0, 10);

  return (
    <div className="w-full flex flex-col gap-5 items-center">
      <div className="w-full flex flex-col items-center justify-center gap-0 sm:gap-5 m-auto text-xl">
        {discoveries.length > 0 ? (
          <>
            <h3 className="text-center">Your travels</h3>
            {isLoading.discoveryByTxHashQuery && <LootIconLoader />}
            <div className="w-full flex flex-col items-center gap-2 overflow-auto">
              {limitedDiscoveries.map((discovery: Discovery, index: number) => (
                <div
                  className="w-full p-1 sm:p-2 text-left border border-terminal-green text-sm sm:text-base"
                  key={index}
                >
                  <DiscoveryDisplay discoveryData={discovery} />
                </div>
              ))}
            </div>
          </>
        ) : (
          <p>You have not yet made any discoveries!</p>
        )}
      </div>
    </div>
  );
};

export default Discovery;
