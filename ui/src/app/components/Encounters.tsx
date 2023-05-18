import { useEffect, useState } from "react";
import { useQueriesStore } from "../hooks/useQueryStore";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import { BattleDisplay } from "./BattleDisplay";
import LootIconLoader from "./Loader";
import { Button } from "./Button";
import { NullBeast } from "../types";
import { processBeastName } from "../lib/utils";
import useAdventurerStore from "../hooks/useAdventurerStore";

export const Encounters = () => {
  const { adventurer } = useAdventurerStore();
  const { data, isLoading } = useQueriesStore();
  const encountersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);

  const [loadingData, setLoadingData] = useState(true);
  const [sortedCombined, setSortedCombined] = useState<any[]>([]);

  const beasts = data.beastsQuery ? data.beastsQuery.beasts : [];

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

      const formattedBattles = battles.map((battle: any) => {
        let beast = beasts.find((beasts: any) => beasts.id === battle.beastId);
        return {
          ...battle,
          beast: beast ? beast : NullBeast,
        };
      });

      const combined = [...formattedDiscoveries, ...formattedBattles];
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
            {displayEncounters.map((encounter: any, index: number) => {
              const beastName = processBeastName(encounter.beast, adventurer);
              return (
                <div
                  className="w-full p-2 text-left border border-terminal-green"
                  key={index}
                >
                  {encounter.hasOwnProperty("discoveryType") ? (
                    <DiscoveryDisplay discoveryData={encounter} />
                  ) : (
                    <BattleDisplay
                      battleData={encounter}
                      beastName={beastName}
                    />
                  )}
                </div>
              );
            })}
          </div>
        </>
      ) : (
        <p>You have not yet made any encounters!</p>
      )}
      {sortedCombined.length > 10 && (
        <div className="flex justify-center mt-8">
          <Button
            variant={"outline"}
            onClick={() => currentPage > 1 && handleClick(currentPage - 1)}
            disabled={currentPage === 1}
          >
            back
          </Button>

          <Button
            variant={"outline"}
            key={1}
            onClick={() => handleClick(1)}
            className={currentPage === 1 ? "animate-pulse" : ""}
          >
            {1}
          </Button>

          {currentPage > 3 && "..."}

          {(
            Array.from({ length: Math.min(5, totalPages - 2) }, (_, i) => {
              const startPage = Math.max(2, currentPage - 2);
              const endPage = Math.min(totalPages - 1, currentPage + 2);
              const pageNum = startPage + i;
              return pageNum <= endPage ? pageNum : null;
            }).filter((pageNum) => pageNum !== null) as number[]
          ).map((pageNum: number) => (
            <Button
              variant={"outline"}
              key={pageNum}
              onClick={() => handleClick(pageNum)}
              className={currentPage === pageNum ? "animate-pulse" : ""}
            >
              {pageNum}
            </Button>
          ))}

          {currentPage < totalPages - 2 && "..."}

          <Button
            variant={"outline"}
            key={totalPages}
            onClick={() => handleClick(totalPages)}
            className={currentPage === totalPages ? "animate-pulse" : ""}
          >
            {totalPages}
          </Button>

          <Button
            variant={"outline"}
            onClick={() =>
              currentPage < totalPages && handleClick(currentPage + 1)
            }
            disabled={currentPage === totalPages}
          >
            next
          </Button>
        </div>
      )}
    </div>
  );
};
