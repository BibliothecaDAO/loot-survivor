import React, { useEffect, useState } from "react";
import {
  getAdventurerByXP,
  getAdventurerById,
  getItemsByAdventurer,
} from "../hooks/graphql/queries";
import { Button } from "../components/buttons/Button";
import { useQueriesStore } from "../hooks/useQueryStore";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { Adventurer } from "../types";
import ScoreTable from "../components/leaderboard/ScoreTable";
import LiveTable from "../components/leaderboard/LiveTable";
import { RefreshIcon } from "../components/icons/Icons";

/**
 * @container
 * @description Provides the leaderboard screen for the adventurer.
 */
export default function LeaderboardScreen() {
  const itemsPerPage = 10;
  const [showScores, setShowScores] = useState(false);

  const { refetch, setData, setIsLoading, setNotLoading } = useQueriesStore();

  const adventurersByXPdata = useCustomQuery(
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined
  );

  const profile = useUIStore((state) => state.profile);

  useCustomQuery("leaderboardByIdQuery", getAdventurerById, {
    id: profile ?? 0,
  });

  useCustomQuery("itemsByProfileQuery", getItemsByAdventurer, {
    id: profile ?? 0,
  });

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
    <div className="flex flex-col items-center justify-between xl:h-[500px] xl:overflow-y-auto 2xl:h-full 2xl:overflow-hidden mt-5 sm:mt-0">
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
        <RefreshIcon className="w-8 h-8" />
      </Button>
      <div className="flex flex-row w-full">
        <div
          className={`${showScores ? "hidden " : ""}sm:block w-full sm:w-1/2`}
        >
          <LiveTable
            itemsPerPage={itemsPerPage}
            handleFetchProfileData={handlefetchProfileData}
          />
        </div>
        <div
          className={`${showScores ? "" : "hidden "}sm:block w-full sm:w-1/2`}
        >
          <ScoreTable
            itemsPerPage={itemsPerPage}
            handleFetchProfileData={handlefetchProfileData}
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
    </div>
  );
}
