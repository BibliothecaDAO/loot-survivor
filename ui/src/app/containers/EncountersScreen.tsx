import { useState } from "react";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { DiscoveryDisplay } from "@/app/components/actions/DiscoveryDisplay";
import { BattleDisplay } from "@/app/components/beast/BattleDisplay";
import LootIconLoader from "@/app/components/icons/Loader";
import { Button } from "@/app/components/buttons/Button";
import { processBeastName } from "@/app/lib/utils";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import {
  getDiscoveriesAndBattlesByAdventurerPaginated,
  getDiscoveryBattleCount,
} from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import useUIStore from "@/app/hooks/useUIStore";

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
  const { isLoading } = useQueriesStore();
  const network = useUIStore((state) => state.network);
  const encountersPerPage = 10;
  const [currentPage, setCurrentPage] = useState<number>(1);
  const skip = (currentPage - 1) * encountersPerPage;

  const discoveryBattleCountData = useCustomQuery(
    network,
    "discoveryBattleCountsQuery",
    getDiscoveryBattleCount,
    {
      adventurerId: profile ? profile : adventurer?.id ?? 0,
    }
  );

  const discoveryBattleCount =
    discoveryBattleCountData?.countDiscoveriesAndBattles;

  const discoveriesAndBattlesData = useCustomQuery(
    network,
    "discoveriesAndBattlesByAdventurerQuery",
    getDiscoveriesAndBattlesByAdventurerPaginated,
    {
      adventurerId: profile ? profile : adventurer?.id ?? 0,
      skip: skip,
    }
  );

  const encounters = discoveriesAndBattlesData?.discoveriesAndBattles ?? [];

  const totalPages = Math.ceil(discoveryBattleCount / encountersPerPage);

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  return (
    <div className="flex flex-col items-center mx-auto text-sm sm:text-xl xl:h-[500px] xl:overflow-y-auto 2xl:h-full 2xl:overflow-hidden w-full">
      {adventurer?.id || profile ? (
        <>
          {discoveryBattleCount > 0 ? (
            <>
              <h3 className="text-center">
                {profile ? "Encounters" : "Your Encounters"}
              </h3>
              {(isLoading.latestDiscoveriesQuery ||
                !discoveriesAndBattlesData) && <LootIconLoader />}
              <div className="flex flex-col items-center gap-2 overflow-auto default-scroll">
                {encounters.map((encounter: any, index: number) => {
                  const formatEncounter = encounter.data;
                  return (
                    <div
                      className="w-full p-1 sm:p-2 text-left border border-terminal-green"
                      key={index}
                    >
                      {formatEncounter.hasOwnProperty("discoveryType") ? (
                        <DiscoveryDisplay discoveryData={formatEncounter} />
                      ) : (
                        <BattleDisplay
                          battleData={formatEncounter}
                          beastName={processBeastName(
                            formatEncounter?.beast,
                            formatEncounter?.special2,
                            formatEncounter?.special3
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
          {discoveryBattleCount > 10 && (
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
