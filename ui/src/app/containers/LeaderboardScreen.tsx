import React, { useEffect, useState } from "react";
import {
  getAdventurerByXP,
  getAdventurerById,
  getItemsByAdventurer,
} from "@/app/hooks/graphql/queries";
import { Button } from "@/app/components/buttons/Button";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { Adventurer } from "@/app/types";
import ScoreTable from "@/app/components/leaderboard/ScoreTable";
import LiveTable from "@/app/components/leaderboard/LiveTable";
import { RefreshIcon } from "@/app/components/icons/Icons";
import LootIconLoader from "@/app/components/icons/Loader";
import { ProfileIcon, SkullIcon } from "@/app/components/icons/Icons";
import { networkConfig } from "@/app/lib/networkConfig";

/**
 * @container
 * @description Provides the leaderboard screen for the adventurer.
 */
export default function LeaderboardScreen() {
  const itemsPerPage = 10;
  const [showScores, setShowScores] = useState(false);

  const { data, refetch, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

  const network = useUIStore((state) => state.network);

  const adventurersByXPdata = useCustomQuery(
    networkConfig[network!].lsGQLURL!,
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined
  );

  const adventurers = data.adventurersByXPQuery?.adventurers
    ? data.adventurersByXPQuery?.adventurers
    : [];

  const aliveAdventurers = adventurers.filter(
    (adventurer) => (adventurer.health ?? 0) > 0
  );

  const scores = adventurers.filter((adventurer) => adventurer.health === 0);

  const profile = useUIStore((state) => state.profile);

  useCustomQuery(
    networkConfig[network!].lsGQLURL!,
    "leaderboardByIdQuery",
    getAdventurerById,
    {
      id: profile ?? 0,
    }
  );

  useCustomQuery(
    networkConfig[network!].lsGQLURL!,
    "itemsByProfileQuery",
    getItemsByAdventurer,
    {
      id: profile ?? 0,
    }
  );

  const handlefetchProfileData = async (adventurerId: number) => {
    setIsLoading();
    const newProfileAdventurerData = await refetch("leaderboardByIdQuery", {
      id: adventurerId,
    });
    const newItemsByProfileData = await refetch("itemsByProfileQuery", {
      id: adventurerId,
    });
    setData("leaderboardByIdQuery", newProfileAdventurerData);
    setData("itemsByProfileQuery", newItemsByProfileData);
    setNotLoading();
  };

  const handleSortXp = (xpData: any) => {
    const copiedAdventurersByXpData = xpData?.adventurers.slice();

    const sortedAdventurersByXPArray = copiedAdventurersByXpData?.sort(
      (a: Adventurer, b: Adventurer) => (b.xp ?? 0) - (a.xp ?? 0)
    );

    const sortedAdventurersByXP = { adventurers: sortedAdventurersByXPArray };
    return sortedAdventurersByXP;
  };

  useEffect(() => {
    if (adventurersByXPdata) {
      setIsLoading();
      const sortedAdventurersByXP = handleSortXp(adventurersByXPdata);
      setData("adventurersByXPQuery", sortedAdventurersByXP);
      setNotLoading();
    }
  }, [adventurersByXPdata]);

  return (
    <div className="flex flex-col items-center h-full xl:overflow-y-auto 2xl:overflow-hidden mt-5 sm:mt-0">
      {!adventurersByXPdata ? (
        <div className="flex justify-center items-center h-full">
          <LootIconLoader className="m-auto" size="w-10" />
        </div>
      ) : (
        <>
          <div className="flex flex-row gap-5 items-center">
            <div className="flex flex-row border border-terminal-green items-center justify-between w-16 h-8 sm:w-24 sm:h-12 px-2">
              <ProfileIcon className="fill-current w-4 h-4 sm:w-8 sm:h-8" />
              <p className="sm:text-2xl">{aliveAdventurers.length}</p>
            </div>
            <Button
              onClick={async () => {
                const adventurersByXPdata = await refetch(
                  "adventurersByXPQuery",
                  undefined
                );
                const sortedAdventurersByXP = handleSortXp(adventurersByXPdata);
                setData("adventurersByXPQuery", sortedAdventurersByXP);
              }}
            >
              <RefreshIcon className="w-4 sm:w-8" />
            </Button>
            <div className="flex flex-row border border-terminal-green items-center justify-between w-16 h-8 sm:w-24 sm:h-12 px-2">
              <SkullIcon className="fill-current w-4 h-4 sm:w-8 sm:h-8" />
              <p className="sm:text-2xl">{scores.length}</p>
            </div>
          </div>
          <div className="flex flex-row w-full">
            <div
              className={`${
                showScores ? "hidden " : ""
              }sm:block w-full sm:w-1/2`}
            >
              <LiveTable
                itemsPerPage={itemsPerPage}
                handleFetchProfileData={handlefetchProfileData}
                adventurers={aliveAdventurers}
              />
            </div>
            <div
              className={`${
                showScores ? "" : "hidden "
              }sm:block w-full sm:w-1/2`}
            >
              <ScoreTable
                itemsPerPage={itemsPerPage}
                handleFetchProfileData={handlefetchProfileData}
                adventurers={scores}
              />
            </div>
          </div>
          <Button
            onClick={() =>
              showScores ? setShowScores(false) : setShowScores(true)
            }
            className="sm:hidden"
          >
            {showScores ? "Show Live Leaderboard" : "Show Scores"}
          </Button>
        </>
      )}
    </div>
  );
}
