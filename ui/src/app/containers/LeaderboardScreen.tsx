import React, { useEffect, useState } from "react";
import { Contract } from "starknet";
import { useBlock } from "@starknet-react/core";
import {
  getAdventurerByXP,
  getAdventurerById,
  getItemsByAdventurer,
} from "@/app/hooks/graphql/queries";
import { Button } from "@/app/components/buttons/Button";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { Adventurer, GameEntropy } from "@/app/types";
import ScoreTable from "@/app/components/leaderboard/ScoreTable";
import LiveTable from "@/app/components/leaderboard/LiveTable";
import { RefreshIcon } from "@/app/components/icons/Icons";
import LootIconLoader from "@/app/components/icons/Loader";
import { ProfileIcon, SkullIcon } from "@/app/components/icons/Icons";
import { IsIdleResult } from "@/app/types";

interface LeaderboardScreenProps {
  slayIdles: (slayAdventurers: string[]) => Promise<void>;
  gameContract: Contract;
}

/**
 * @container
 * @description Provides the leaderboard screen for the adventurer.
 */
export default function LeaderboardScreen({
  slayIdles,
  gameContract,
}: LeaderboardScreenProps) {
  const itemsPerPage = 10;
  const [showScores, setShowScores] = useState(false);
  const [gameEntropyUpdateTime, setGameEntropyUpdateTime] = useState<
    number | null
  >();
  const [idleAdventurers, setIdleAdventurers] = useState<
    string[] | undefined
  >();
  const [loadingIdles, setLoadingIdles] = useState(false);

  const { data: blockData } = useBlock({
    refetchInterval: false,
  });

  const currentBlock = blockData?.block_number;

  const { data, refetch, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

  const adventurersByXPdata = useCustomQuery(
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

  const getGameEntropy = async () => {
    const gameEntropy = await gameContract.call("get_game_entropy");
    const formattedEntropy = gameEntropy as GameEntropy;
    const gameEntropyUpdateTime =
      Number(formattedEntropy.next_update_block) -
      Number(formattedEntropy.last_updated_block);
    setGameEntropyUpdateTime(gameEntropyUpdateTime);
  };

  const getIdleAdventurers = async (adventurers: Adventurer[]) => {
    setLoadingIdles(true);
    const idleAdventurers = [];
    for (let adventurer of adventurers) {
      const isIdleResult = await gameContract.call("is_idle", [
        adventurer?.id ?? "0",
      ]);
      const isIdle = (isIdleResult as IsIdleResult)["0"];
      if (isIdle) {
        idleAdventurers.push(adventurer?.id?.toString() ?? "0");
      }
    }
    console.log(idleAdventurers);
    setIdleAdventurers(idleAdventurers);
    setLoadingIdles(false);
  };

  useEffect(() => {
    getGameEntropy();
  }, []);

  useEffect(() => {
    if (data.adventurersByXPQuery?.adventurers) {
      getIdleAdventurers(aliveAdventurers);
    }
  }, [adventurers]);

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
              onClick={async () => await slayIdles(idleAdventurers!)}
              disabled={loadingIdles || idleAdventurers?.length === 0}
            >
              {loadingIdles ? (
                <p className="loading-ellipsis">Loading Idles</p>
              ) : idleAdventurers?.length === 0 ? (
                "No Idle Adventurers"
              ) : (
                "Slay Idle Adventurers"
              )}
            </Button>
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
                gameContract={gameContract}
                gameEntropyUpdateTime={gameEntropyUpdateTime!}
                currentBlock={currentBlock!}
                idleAdventurers={idleAdventurers}
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
