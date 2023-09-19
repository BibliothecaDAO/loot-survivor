import React, { useEffect, useState } from "react";
import {
  getAdventurersInListByXp,
  getTopScores,
  getAdventurerByXP,
  getAdventurerById,
  getItemsByAdventurer,
} from "../hooks/graphql/queries";
import { Button } from "../components/buttons/Button";
import { CoinIcon } from "../components/icons/Icons";
import Lords from "../../../public/lords.svg";
import LootIconLoader from "../components/icons/Loader";
import { useQueriesStore } from "../hooks/useQueryStore";
import useUIStore from "../hooks/useUIStore";
import useCustomQuery from "../hooks/useCustomQuery";
import { Score, Adventurer } from "../types";
import { useUiSounds, soundSelector } from "../hooks/useUiSound";
import KillAdventurer from "../components/actions/KillAdventurer";
import ScoreTable from "../components/leaderboard/ScoreTable";
import LiveTable from "../components/leaderboard/LiveTable";
import useLoadingStore from "../hooks/useLoadingStore";

/**
 * @container
 * @description Provides the leaderboard screen for the adventurer.
 */
export default function LeaderboardScreen() {
  const itemsPerPage = 10;
  const [loading, setLoading] = useState(false);
  const [showScores, setShowScores] = useState(false);
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  const { data, isLoading, refetch, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

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

  useEffect(() => {
    if (adventurersByXPdata) {
      setIsLoading();
      setData("adventurersByXPQuery", adventurersByXPdata);
      setNotLoading();
    }
  }, [adventurersByXPdata]);

  console.log(adventurersByXPdata);

  return (
    <div className="flex flex-col sm:flex-row items-center sm:items-start justify-between xl:h-[500px] xl:overflow-y-auto 2xl:h-full 2xl:overflow-hidden">
      <div className={`${showScores ? "hidden " : ""}sm:block w-full sm:w-1/2`}>
        <LiveTable
          itemsPerPage={itemsPerPage}
          handleFetchProfileData={handlefetchProfileData}
        />
      </div>
      <div className={`${showScores ? "" : "hidden "}sm:block w-full sm:w-1/2`}>
        <ScoreTable
          itemsPerPage={itemsPerPage}
          handleFetchProfileData={handlefetchProfileData}
        />
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
