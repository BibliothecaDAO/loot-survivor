import { useEffect, useState } from "react";
import { useQueriesStore } from "../hooks/useQueryStore";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import { BattleDisplay } from "./BattleDisplay";
import LootIconLoader from "./Loader";
import { Button } from "./Button";

export const Encounters = () => {
  const { data, isLoading } = useQueriesStore();
  const encountersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);

  const [loadingData, setLoadingData] = useState(true);
  const [sortedCombined, setSortedCombined] = useState<any[]>([]);

  useEffect(() => {
    if (data) {
      setLoadingData(true);

      const discoveries = data.discoveriesQuery
        ? data.discoveriesQuery.discoveries
        : [];

      const battles = data.battlesByAdventurerQuery
        ? data.battlesByAdventurerQuery.battles
        : [];

      const formattedDiscoveries = discoveries.map((discovery: any) => ({
        ...discovery,
        timestamp: discovery.discoveryTime,
      }));

      const combined = [...formattedDiscoveries, ...battles];
      const sorted = combined.sort((a: any, b: any) => {
        const dateA = new Date(a.timestamp);
        const dateB = new Date(b.timestamp);
        return dateB.getTime() - dateA.getTime();
      });

      setSortedCombined(sorted);
      setLoadingData(false);
    }
  }, [data]); // Runs whenever 'data' changes

  const totalPages = Math.ceil(sortedCombined.length / encountersPerPage);

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  const displayEncounters = sortedCombined.slice(
    (currentPage - 1) * encountersPerPage,
    currentPage * encountersPerPage
  );

  return (
    <div className="flex flex-col items-center m-auto text-xl">
      {displayEncounters.length > 0 ? (
        <>
          <h3 className="text-center">Your encounters</h3>
          {(isLoading.latestDiscoveriesQuery ||
            isLoading.battlesByBeastQuery ||
            loadingData) && <LootIconLoader />}
          <div className="flex flex-col items-center gap-2 overflow-auto">
            {displayEncounters.map((encounter: any, index: number) => (
              <div
                className="w-full p-2 text-left border border-terminal-green"
                key={index}
              >
                {encounter.hasOwnProperty("discoveryType") ? (
                  <DiscoveryDisplay discoveryData={encounter} />
                ) : (
                  <BattleDisplay battleData={encounter} beastName="" />
                )}
              </div>
            ))}
          </div>
        </>
      ) : (
        <p>You have not yet made any encounters!</p>
      )}
      <div className="flex justify-center mt-8">
        <Button
          variant={"outline"}
          onClick={() => handleClick(currentPage - 1)}
        >
          back
        </Button>
        {Array.from({ length: totalPages }, (_, i) => i + 1).map(
          (pageNum: number) => (
            <Button
              variant={"outline"}
              key={pageNum}
              onClick={() => handleClick(pageNum)}
              className={currentPage === pageNum ? "animate-pulse" : ""}
            >
              {pageNum}
            </Button>
          )
        )}
        <Button
          variant={"outline"}
          onClick={() => handleClick(currentPage + 1)}
        >
          next
        </Button>
      </div>
    </div>
  );
};
