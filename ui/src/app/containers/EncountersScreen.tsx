import { useEffect, useState } from "react";
import { useQueriesStore } from "../hooks/useQueryStore";
import { DiscoveryDisplay } from "../components/actions/DiscoveryDisplay";
import { BattleDisplay } from "../components/beast/BattleDisplay";
import LootIconLoader from "../components/icons/Loader";
import { Button } from "../components/buttons/Button";
import { Battle, Discovery, NullAdventurer, NullDiscovery } from "../types";
import { processBeastName } from "../lib/utils";
import useAdventurerStore from "../hooks/useAdventurerStore";
import {
  getAdventurerById,
  getBattlesByAdventurer,
  getDiscoveries,
  getLastBeastDiscovery,
} from "../hooks/graphql/queries";
import { useQuery } from "@apollo/client";
import useCustomQuery from "../hooks/useCustomQuery";
import useLoadingStore from "../hooks/useLoadingStore";

export interface EncountersProps {
  profile?: number;
}
interface FormattedDiscovery extends Discovery {
  timestamp: Date | undefined;
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
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const [loadingData, setLoadingData] = useState(true);
  const [sortedCombined, setSortedCombined] = useState<Battle[] | Discovery[]>(
    []
  );

  let lastBeast = data.lastBeastQuery
    ? data.lastBeastQuery.discoveries[0]
    : NullDiscovery;

  const formatBattles = data.battlesByBeastQuery
    ? data.battlesByBeastQuery.battles
    : [];

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: profile ? profile : adventurer?.id ?? 0,
    },
    txAccepted
  );

  const { data: discoveriesByAdventurerData } = useQuery(getDiscoveries, {
    variables: {
      adventurerId: profile ? profile : adventurer?.id ?? 0,
    },
  });

  const { data: battlesByAdventurerData } = useQuery(getBattlesByAdventurer, {
    variables: {
      adventurerId: profile ? profile : adventurer?.id ?? 0,
    },
  });

  useEffect(() => {
    if (data) {
      setLoadingData(true);

      const discoveries = discoveriesByAdventurerData
        ? discoveriesByAdventurerData.discoveries
        : [];

      const battles = battlesByAdventurerData
        ? battlesByAdventurerData.battles
        : [];

      const combined = [...discoveries, ...battles];
      const sorted = combined.sort((a: any, b: any) => {
        const dateA = new Date(a.timestamp);
        const dateB = new Date(b.timestamp);
        return dateB.getTime() - dateA.getTime();
      });

      setSortedCombined(sorted);
      setLoadingData(false);
    }
  }, [discoveriesByAdventurerData, battlesByAdventurerData, data]); // Runs whenever 'data' changes

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

  // if (!discoveriesByAdventurerData || !battlesByAdventurerData) {
  //   return (
  //     <div className="flex flex-col items-center m-auto">
  //       <LootIconLoader />
  //     </div>
  //   );
  // }

  return (
    <div className="flex flex-col items-center mx-auto text-sm sm:text-xl">
      {displayEncounters.length > 0 ? (
        <>
          <h3 className="text-center">
            {profile ? "Encounters" : "Your Encounters"}
          </h3>
          {(isLoading.latestDiscoveriesQuery || loadingData) && (
            <LootIconLoader />
          )}
          <div className="flex flex-col items-center gap-2 overflow-auto">
            {displayEncounters.map((encounter: any, index: number) => {
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
                      battles={formatBattles}
                      beastName={processBeastName(
                        encounter?.beast,
                        encounter?.special2,
                        encounter?.special3
                      )}
                      adventurer={adventurer ?? NullAdventurer}
                      discoveryData={lastBeast}
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
}
