import React, { useState, useRef, useEffect } from "react";
import { useQuery } from "@apollo/client";
import { getAdventurerById } from "../hooks/graphql/queries";
import { Button } from "./Button";
import Coin from "../../../public/coin.svg";
import Lords from "../../../public/lords.svg";
import LootIconLoader from "./Loader";
import { useQueriesStore } from "../hooks/useQueryStore";
import useCustomQuery from "../hooks/useCustomQuery";
import useUIStore from "../hooks/useUIStore";

const Leaderboard: React.FC = () => {
  const [currentPage, setCurrentPage] = useState<number>(1);
  const itemsPerPage = 10;
  const ref = useRef<HTMLTableRowElement | null>(null);

  const setScreen = useUIStore((state) => state.setScreen);
  const setProfile = useUIStore((state) => state.setProfile);

  const handleRowSelected = (adventurerId: number) => {
    setProfile(adventurerId);
    setScreen("profile");
  };

  const { data, isLoading } = useQueriesStore();

  if (isLoading.adventurersByXPQuery)
    return (
      <div className="flex justify-center p-20 align-middle">
        <LootIconLoader />
      </div>
    );

  const adventurers = data?.adventurersByXPQuery?.adventurers;
  const scores = data?.topScoresQuery?.scores;

  const totalPages = Math.ceil(adventurers.length / itemsPerPage);

  const handleClick = (newPage: number): void => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  const displayAdventurers = adventurers.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  let previousGold = -1;
  let currentRank = 0;
  let rankOffset = 0;

  const rankGold = (adventurer: any, index: number) => {
    if (adventurer.xp !== previousGold) {
      currentRank = index + 1 + (currentPage - 1) * itemsPerPage;
      rankOffset = 0;
    } else {
      rankOffset++;
    }
    previousGold = adventurer.xp;
    return currentRank;
  };

  return (
    <div className="flex flex-col items-center w-3/4 m-auto">
      <h1 className="text-2xl">Top 3 Submitted Scores</h1>
      <table className="w-full mt-4 text-xl border border-terminal-green">
        <thead className="border border-terminal-green">
          <tr>
            <th className="p-1">Rank</th>
            <th className="p-1">Adventurer</th>
            <th className="p-1">XP</th>
            <th className="p-1">
              Prize <span className="text-sm">(per mint)</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {scores.map((score: any, index: number) => (
            <tr
              key={index}
              className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer"
              onClick={() => handleRowSelected(score.adventurerId)}
            >
              <td>{index + 1}</td>
              <td>{score.adventurerId}</td>
              <td>{score.xp}</td>
              <td>
                <div className="flex flex-row items-center justify-center gap-2">
                  <span
                    className={` ${
                      index == 0
                        ? "text-gold"
                        : index == 1
                        ? "text-silver"
                        : index == 2
                        ? "text-bronze"
                        : ""
                    }`}
                  >
                    {index == 0 ? 10 : index == 1 ? 3 : index == 2 ? 2 : ""}
                  </span>

                  <Lords className="self-center w-6 h-6 ml-4 fill-current" />
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <h1 className="text-2xl">Live Leaderboard</h1>
      <table className="w-full mt-4 text-xl border border-terminal-green">
        <thead className="border border-terminal-green">
          <tr>
            <th className="p-1">Rank</th>
            <th className="p-1">Adventurer</th>
            <th className="p-1">Gold</th>
            <th className="p-1">XP</th>
            <th className="p-1">Health</th>
          </tr>
        </thead>
        <tbody>
          {displayAdventurers.map((adventurer: any, index: number) => {
            const dead = adventurer.health <= 0;
            return (
              <tr
                key={adventurer.id}
                className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black cursor-pointer"
                onClick={() => handleRowSelected(adventurer.id)}
              >
                <td>{rankGold(adventurer, index)}</td>
                <td>{`${adventurer.name} - ${adventurer.id}`}</td>
                <td>
                  <span className="flex justify-center text-terminal-yellow">
                    <Coin className="self-center w-6 h-6 fill-current" />
                    {adventurer.gold ? adventurer.gold : 0}
                  </span>
                </td>
                <td>
                  <span className="flex justify-center">{adventurer.xp}</span>
                </td>
                <td>
                  <span
                    className={`flex justify-center ${
                      !dead ? " text-terminal-green" : "text-red-800"
                    }`}
                  >
                    {adventurer.health}
                  </span>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      <div className="flex justify-center mt-8">
        <Button
          variant={"outline"}
          onClick={() => handleClick(currentPage - 1)}
        >
          back
        </Button>
        {Array.from({ length: totalPages }, (_, i) => i + 1).map(
          (pageNum: number) => (
            <Button
              variant={"outline"}
              key={pageNum}
              onClick={() => handleClick(pageNum)}
              className={currentPage === pageNum ? "animate-pulse" : ""}
            >
              {pageNum}
            </Button>
          )
        )}
        <Button
          variant={"outline"}
          onClick={() => handleClick(currentPage + 1)}
        >
          next
        </Button>
      </div>
    </div>
  );
};

export default Leaderboard;
