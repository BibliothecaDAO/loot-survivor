import { useState } from "react";
import { Button } from "../../components/buttons/Button";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { Adventurer } from "@/app/types";
import ScoreRow from "./ScoreRow";
import useUIStore from "@/app/hooks/useUIStore";

export interface ScoreLeaderboardTableProps {
  itemsPerPage: number;
}

const ScoreLeaderboardTable = ({
  itemsPerPage,
}: ScoreLeaderboardTableProps) => {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [loading, setLoading] = useState(false);
  const { data, isLoading, refetch } = useQueriesStore();
  const scores = data.adventurersInListByXpQuery?.adventurers
    ? data.adventurersInListByXpQuery?.adventurers
    : [];
  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);
  const displayScores = scores?.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );
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
    <div className="flex sm:w-1/2 flex-col items-center py-2">
      <h4 className="text-lg text-center sm:text-2xl m-0">Submitted Scores</h4>
      {scores.length > 0 ? (
        <div className="flex flex-col w-full gap-5">
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
              {displayScores.map((adventurer: Adventurer, index: number) => (
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
