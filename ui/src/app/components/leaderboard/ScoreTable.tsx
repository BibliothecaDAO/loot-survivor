import { useState } from "react";
import { Button } from "../../components/buttons/Button";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { Adventurer } from "@/app/types";
import ScoreRow from "./ScoreRow";
import useUIStore from "@/app/hooks/useUIStore";
import { getScoresInList } from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";

export interface ScoreLeaderboardTableProps {
  itemsPerPage: number;
  handleFetchProfileData: (adventurerId: number) => void;
}

const ScoreLeaderboardTable = ({
  itemsPerPage,
  handleFetchProfileData,
}: ScoreLeaderboardTableProps) => {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [loading, setLoading] = useState(false);
  const { data } = useQueriesStore();
  const adventurers = data.adventurersByXPQuery?.adventurers
    ? data.adventurersByXPQuery?.adventurers
    : [];
  const scores = adventurers.filter((adventurer) => adventurer.health === 0);
  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);
  const displayScores = scores?.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const scoreIds = scores?.map((score) => score.id ?? 0);

  console.log(scoreIds);

  const scoresData = useCustomQuery("topScoresQuery", getScoresInList, {
    ids: scoreIds,
  });

  const mergedScores = displayScores.map((item1) => {
    const matchingItem2 = scoresData?.scores.find(
      (item2: any) => item2.adventurerId === item1.id
    );

    return {
      ...item1,
      ...matchingItem2,
    };
  });

  const scoresWithLords = mergedScores;

  console.log(scoresWithLords);
  console.log(scoresData);

  const totalPages = Math.ceil(scores.length / itemsPerPage);

  let previousXp = -1;
  let currentRank = 0;
  let rankOffset = 0;

  const rankXp = (adventurer: Adventurer, index: number) => {
    if (adventurer.xp !== previousXp) {
      currentRank = index + 1 + (currentPage - 1) * itemsPerPage;
      rankOffset = 0;
    } else {
      rankOffset++;
    }
    previousXp = adventurer.xp ?? 0;
    return currentRank;
  };

  const handleRowSelected = async (adventurerId: number) => {
    setLoading(true);
    try {
      setProfile(adventurerId);
      setScreen("profile");
      await handleFetchProfileData(adventurerId);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  return (
    <div className="flex flex-col items-center p-2 gap-2">
      <h4 className="text-2xl text-center sm:text-2xl m-0">Leaderboard</h4>
      {scores.length > 0 ? (
        <div className="flex flex-col w-full gap-5">
          <table className="w-full sm:text-lg xl:text-xl border border-terminal-green">
            <thead className="border border-terminal-green">
              <tr>
                <th className="p-1">Rank</th>
                <th className="p-1">Adventurer</th>
                <th className="p-1">XP</th>
                <th className="p-1">Payout</th>
              </tr>
            </thead>
            <tbody>
              {scoresWithLords.map((adventurer: any, index: number) => (
                <ScoreRow
                  key={index}
                  index={index}
                  adventurer={adventurer}
                  rank={rankXp(adventurer, index)}
                  handleRowSelected={handleRowSelected}
                />
              ))}
            </tbody>
          </table>
          {scores?.length > 10 && (
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
      ) : (
        <h3 className="text-lg sm:text-2xl py-4">
          No scores submitted yet. Be the first!
        </h3>
      )}
    </div>
  );
};

export default ScoreLeaderboardTable;
