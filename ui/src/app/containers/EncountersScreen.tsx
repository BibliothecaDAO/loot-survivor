import { useEffect, useState } from "react";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { DiscoveryDisplay } from "@/app/components/actions/DiscoveryDisplay";
import { BattleDisplay } from "@/app/components/beast/BattleDisplay";
import LootIconLoader from "@/app/components/icons/Loader";
import { Button } from "@/app/components/buttons/Button";
import { Battle, Discovery } from "@/app/types";
import { processBeastName } from "@/app/lib/utils";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import {
  getBattlesByAdventurer,
  getDiscoveries,
} from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";

export interface EncountersProps {
  profile?: number;
}

/**
 * @container
 * @description Provides the encounters screen for the adventurer.
 * @prop {number} profile - The adventurer profile to have encounters displayed.
 */
export default function EncountersScreen({ profile }: EncountersProps) {
  const { adventurer } = useAdventurerStore();
  const { data, isLoading } = useQueriesStore();
  const encountersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [loadingData, setLoadingData] = useState(true);
  const [sortedCombined, setSortedCombined] = useState<Battle[] | Discovery[]>(
    []
  );

  const discoveriesData = useCustomQuery("discoveriesQuery", getDiscoveries, {
    id: profile ? profile : adventurer?.id ?? 0,
  });

  const battlesData = useCustomQuery(
    "battlesByAdventurerQuery",
    getBattlesByAdventurer,
    {
      adventurerId: profile ? profile : adventurer?.id ?? 0,
    }
  );

  useEffect(() => {
    if (data) {
      setLoadingData(true);

      const discoveries = discoveriesData?.discoveries
        ? discoveriesData?.discoveries
        : [];

      const battles = battlesData?.battles ? battlesData?.battles : [];

      const combined = [...discoveries, ...battles];
      const sorted = combined.sort((a: any, b: any) => {
        const dateA = new Date(a.timestamp);
        const dateB = new Date(b.timestamp);
        return dateB.getTime() - dateA.getTime();
      });

      setSortedCombined(sorted);
      setLoadingData(false);
    }
  }, [discoveriesData, battlesData, data]); // Runs whenever 'data' changes

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
    <div className="flex flex-col items-center mx-auto text-sm sm:text-xl xl:h-[500px] xl:overflow-y-auto 2xl:h-full 2xl:overflow-hidden w-full">
      {adventurer?.id || profile ? (
        <>
          {displayEncounters.length > 0 ? (
            <>
              <h3 className="text-center">
                {profile ? "Encounters" : "Your Encounters"}
              </h3>
              {(isLoading.latestDiscoveriesQuery || loadingData) && (
                <LootIconLoader />
              )}
              <div className="flex flex-col items-center gap-2 overflow-auto default-scroll">
                {displayEncounters.map((encounter: any, index: number) => {
                  return (
                    <div
                      className="w-full p-1 sm:p-2 text-left border border-terminal-green"
                      key={index}
                    >
                      {encounter.hasOwnProperty("discoveryType") ? (
                        <DiscoveryDisplay discoveryData={encounter} />
                      ) : (
                        <BattleDisplay
                          battleData={encounter}
                          beastName={processBeastName(
                            encounter?.beast,
                            encounter?.special2,
                            encounter?.special3
                          )}
                        />
                      )}
                    </div>
                  );
                })}
              </div>
            </>
          ) : (
            <p className="text-lg">You have not yet made any encounters!</p>
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
        </>
      ) : (
        <h3>Please select an adventurer!</h3>
      )}
    </div>
  );
}
