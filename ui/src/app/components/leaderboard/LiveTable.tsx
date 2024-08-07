import { useState, useMemo } from "react";
import { getAliveAdventurersByXPPaginated } from "@/app/hooks/graphql/queries";
import { Button } from "@/app/components/buttons/Button";
import { Adventurer } from "@/app/types";
import LiveRow from "@/app/components/leaderboard/LiveRow";
import useUIStore from "@/app/hooks/useUIStore";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import LootIconLoader from "@/app/components/icons/Loader";

export interface LiveLeaderboardTableProps {
  itemsPerPage: number;
  handleFetchProfileData: (adventurerId: number) => void;
  adventurerCount: number;
}

const LiveLeaderboardTable = ({
  itemsPerPage,
  handleFetchProfileData,
  adventurerCount,
}: LiveLeaderboardTableProps) => {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);
  const network = useUIStore((state) => state.network);
  const skip = (currentPage - 1) * itemsPerPage;
  const totalPages = Math.ceil(adventurerCount / itemsPerPage);

  const aliveAdventurersVariables = useMemo(() => {
    return {
      skip: skip,
    };
  }, [skip]);

  const adventurersByXPdata = useCustomQuery(
    network,
    "adventurersByXPQuery",
    getAliveAdventurersByXPPaginated,
    aliveAdventurersVariables
  );

  const adventurers: Adventurer[] = adventurersByXPdata?.adventurers ?? [];

  const handleRowSelected = async (adventurerId: number) => {
    try {
      setProfile(adventurerId);
      setScreen("profile");
      await handleFetchProfileData(adventurerId);
    } catch (error) {
      console.error(error);
    } finally {
    }
  };

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };
  return (
    <>
      {!adventurersByXPdata ? (
        <div className="flex justify-center items-center h-full">
          <LootIconLoader className="m-auto" size="w-10" />
        </div>
      ) : (
        <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row justify-between w-full">
          <div className="flex flex-col w-full sm:mr-4 flex-grow-2 p-2 gap-2">
            <h4 className="text-center text-2xl m-0">Active Games</h4>
            <table className="w-full xl:text-lg 2xl:text-xl border border-terminal-green">
              <thead className="border border-terminal-green">
                <tr>
                  <th className="p-1">Adventurer</th>
                  <th className="p-1">Level</th>
                  <th className="p-1">XP</th>
                  <th className="p-1">Gold</th>
                  <th className="p-1">Health</th>
                </tr>
              </thead>
              <tbody>
                {adventurers?.map((adventurer: Adventurer, index: number) => (
                  <LiveRow
                    key={index}
                    adventurer={adventurer}
                    handleRowSelected={handleRowSelected}
                  />
                ))}
              </tbody>
            </table>
            {adventurerCount > 10 && (
              <div className="flex justify-center sm:mt-8 xl:mt-2">
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
        </div>
      )}
    </>
  );
};

export default LiveLeaderboardTable;
