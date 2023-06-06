import Info from "./Info";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Button } from "./Button";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getAdventurerById,
  getDiscoveries,
  getBattlesByAdventurer,
} from "../hooks/graphql/queries";
import { useEffect, useState } from "react";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import { BattleDisplay } from "./BattleDisplay";
import { NullBeast } from "../types";
import { processBeastName } from "../lib/utils";

export default function Profile() {
  const { data } = useQueriesStore();
  const profile = useUIStore((state) => state.profile);
  useCustomQuery(
    "leaderboardByIdQuery",
    getAdventurerById,
    {
      id: profile ?? 0,
    },
    undefined
  );
  const adventurer = data.leaderboardByIdQuery?.adventurers[0];
  useCustomQuery("discoveriesQuery", getDiscoveries, {
    adventurerId: adventurer?.id ?? 0,
  });

  useCustomQuery("battlesByAdventurerQuery", getBattlesByAdventurer, {
    adventurerId: adventurer?.id ?? 0,
  });
  const setScreen = useUIStore((state) => state.setScreen);
  const encountersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [sortedCombined, setSortedCombined] = useState<any[]>([]);

  const beasts = data.beastsQuery ? data.beastsQuery.beasts : [];

  useEffect(() => {
    if (data) {
      const discoveries = data.discoveriesQuery
        ? data.discoveriesQuery.discoveries
        : [];
      console.log(discoveries);

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
    <div className="w-full m-auto">
      <div className="flex flex-row gap-10 items-start justify-center">
        <Button
          className="animate-pulse"
          onClick={() => setScreen("leaderboard")}
        >
          Back
        </Button>
        <div className="w-1/3 ml-4">
          <Info adventurer={adventurer} profileExists={true} />
        </div>
        <div className="flex flex-col gap-5 justify-center">
          <h3 className="text-center">Encounters</h3>
          <div className="flex flex-col items-center gap-2 overflow-auto">
            {displayEncounters.map((encounter: any, index: number) => {
              let beastName = processBeastName(encounter.beast);
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
      </div>
    </div>
  );
}
