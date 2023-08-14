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
import ScoreRow from "../components/leaderboard/ScoreRow";
import LiveRow from "../components/leaderboard/LiveRow";
import useLoadingStore from "../hooks/useLoadingStore";

/**
 * @container
 * @description Provides the leaderboard screen for the adventurer.
 */
export default function LeaderboardScreen() {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const itemsPerPage = 10;
  const [loading, setLoading] = useState(false);

  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  const handleRowSelected = async (adventurerId: number) => {
    setLoading(true);
    try {
      setProfile(adventurerId);
      setScreen("profile");
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

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

  const scores = data.adventurersInListByXpQuery?.adventurers
    ? data.adventurersInListByXpQuery?.adventurers
    : [];

  useCustomQuery("topScoresQuery", getTopScores, undefined, false);

  if (isLoading.adventurersByXPQuery || loading)
    return (
      <div className="flex justify-center p-20 align-middle">
        <LootIconLoader />
      </div>
    );

  const adventurers = data.adventurersByXPQuery?.adventurers
    ? data.adventurersByXPQuery?.adventurers
    : [];

  const totalPages = Math.ceil(adventurers.length / itemsPerPage);

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  const displayAdventurers = adventurers?.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  let previousGold = -1;
  let currentRank = 0;
  let rankOffset = 0;

  const rankGold = (adventurer: Adventurer, index: number) => {
    if (adventurer.xp !== previousGold) {
      currentRank = index + 1 + (currentPage - 1) * itemsPerPage;
      rankOffset = 0;
    } else {
      rankOffset++;
    }
    previousGold = adventurer.xp ?? 0;
    return currentRank;
  };

  return (
    <div className="flex flex-row items-cente justify-between sm:w-3/4 sm:m-auto">
      <div className="sm:w-1/2 flex flex-col gap-5 sm:gap-0 sm:flex-row justify-between w-full">
        <div className="flex flex-col w-full sm:mb-4 sm:mb-0 sm:mr-4 flex-grow-2 p-2">
          <h4 className="text-center text-lg sm:text-2xl m-0">
            Live Leaderboard
          </h4>
          <table className="w-full text-sm sm:text-xl border border-terminal-green">
            <thead className="border border-terminal-green">
              <tr>
                <th className="p-1">Rank</th>
                <th className="p-1">Adventurer</th>
                <th className="p-1">Gold</th>
                <th className="p-1">XP</th>
                <th className="p-1">Health</th>
                <th className="p-1">Idle</th>
              </tr>
            </thead>
            <tbody>
              {displayAdventurers?.map(
                (adventurer: Adventurer, index: number) => (
                  <LiveRow
                    key={index}
                    index={index}
                    adventurer={adventurer}
                    rank={rankGold(adventurer, index)}
                    handleRowSelected={handleRowSelected}
                  />
                )
              )}
            </tbody>
          </table>
          {adventurers?.length > 10 && (
            <div className="flex justify-center sm:mt-8">
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
      </div>
      <div className="hidden sm:block sm:w-1/2 flex flex-col items-center py-2">
        <h4 className="text-lg text-center sm:text-2xl m-0">
          Submitted Scores
        </h4>
        {scores.length > 0 ? (
          <div className="flex flex-col">
            <table className="w-full text-sm sm:text-xl border border-terminal-green">
              <thead className="border border-terminal-green">
                <tr>
                  <th className="p-1">Rank</th>
                  <th className="p-1">Adventurer</th>
                  <th className="p-1">XP</th>
                  {/* <th className="p-1">
                    Prize <span className="text-sm">(per mint)</span>
                  </th> */}
                </tr>
              </thead>
              <tbody>
                {scores.map((adventurer: Adventurer, index: number) => (
                  <ScoreRow
                    key={index}
                    index={index}
                    adventurer={adventurer}
                    handleRowSelected={handleRowSelected}
                  />
                ))}
              </tbody>
            </table>
            {adventurers?.length > 10 && (
              <div className="flex justify-center sm:mt-8">
                <Button
                  variant={"outline"}
                  onClick={() =>
                    currentPage > 1 && handleClick(currentPage - 1)
                  }
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
        ) : (
          <h3 className="text-lg sm:text-2xl py-4">
            No scores submitted yet. Be the first!
          </h3>
        )}
      </div>
    </div>
  );
}
