import { useState } from "react";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { Adventurer, NullAdventurer } from "@/app/types";
import { useBlock } from "@starknet-react/core";
import useUIStore from "@/app/hooks/useUIStore";
import LobbyRow from "@/app/components/interlude/LobbyRow";
import { Button } from "@/app/components/buttons/Button";

export default function Lobby() {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const { setData, refetch, setIsLoading, setNotLoading } = useQueriesStore();
  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);
  const adventurers = useQueriesStore(
    (state) => state.data.adventurersByXPQuery?.adventurers ?? [NullAdventurer]
  );
  const { data: blockData } = useBlock({
    refetchInterval: false,
  });
  const handleFilterLobby = (adventurers: Adventurer[]) => {
    return adventurers.filter(
      (adventurer) => adventurer?.revealBlock! > blockData?.block_number!
    );
  };

  const handleFetchProfileData = async (adventurerId: number) => {
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

  const handleRowSelected = async (adventurerId: number) => {
    try {
      setProfile(adventurerId);
      setScreen("profile");
      await handleFetchProfileData(adventurerId);
    } catch (error) {
      console.error(error);
    }
  };

  const itemsPerPage = 10;

  const totalPages = Math.ceil(
    handleFilterLobby(adventurers).length / itemsPerPage
  );

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  return (
    <div>
      <p>Lobby</p>
      <table className="w-full xl:text-lg 2xl:text-xl border border-terminal-green">
        <thead className="border border-terminal-green">
          <tr>
            <th className="p-1">Name</th>
            <th className="p-1">Account</th>
            <th className="p-1">Death Toll</th>
            <th className="p-1">Best Run</th>
            <th className="p-1">Blocks Left</th>
          </tr>
        </thead>
        <tbody>
          {handleFilterLobby(adventurers)?.map(
            (adventurer: Adventurer, index: number) => (
              <LobbyRow
                key={index}
                adventurer={adventurer}
                handleRowSelected={handleRowSelected}
                currentBlock={blockData?.block_number!}
              />
            )
          )}
        </tbody>
      </table>
      {handleFilterLobby(adventurers)?.length > 10 && (
        <div className="flex justify-center sm:mt-8 xl:mt-2">
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
