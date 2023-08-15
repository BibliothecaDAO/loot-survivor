import React, { useState } from "react";
import {
  getAdventurersInListByXp,
  getTopScores,
  getAdventurerByXP,
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

  const { data, isLoading, refetch } = useQueriesStore();

  useCustomQuery(
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined,
    txAccepted
  );

  useCustomQuery(
    "adventurersInListByXpQuery",
    getAdventurersInListByXp,
    {
      ids: data.topScoresQuery?.scores
        ? data.topScoresQuery?.scores.map(
            (score: Score) => score.adventurerId ?? 0
          )
        : [0],
    },
    txAccepted
  );

  useCustomQuery("topScoresQuery", getTopScores, undefined, false);

  if (isLoading.adventurersByXPQuery || loading)
    return (
      <div className="flex justify-center p-20 align-middle">
        <LootIconLoader />
      </div>
    );

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between sm:w-3/4 sm:m-auto">
      <div className={`${showScores ? "hidden " : ""}sm:block w-full`}>
        <LiveTable itemsPerPage={itemsPerPage} />
      </div>
      <div className={`${showScores ? "" : "hidden "}sm:block w-full`}>
        <ScoreTable itemsPerPage={itemsPerPage} />
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
