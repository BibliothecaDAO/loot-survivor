import React, { useState } from "react";
import { useAdventurer } from "../context/AdventurerProvider";
import { useQuery } from "@apollo/client";
import { getAdventurerByGold } from "../hooks/graphql/queries";
import { Button } from "./Button";
import Coin from "../../../public/coin.svg";

const Leaderboard: React.FC = () => {
  const adventurer = useAdventurer();
  const [currentPage, setCurrentPage] = useState<number>(1);
  const itemsPerPage = 10;

  const { data, loading, error } = useQuery(getAdventurerByGold);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  const adventurers = data?.adventurers;
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

  return (
    <div className="flex flex-col items-center w-1/2 m-auto">
      <table className="w-full mt-4 text-4xl border border-terminal-green">
        <thead className="sticky top-0 border border-terminal-green">
          <tr>
            <th>Rank</th>
            <th>Adventurer</th>
            <th>Gold</th>
          </tr>
        </thead>
        <tbody>
          {displayAdventurers.map((adventurer: any, index: number) => (
            <tr
              key={adventurer.id}
              className="text-center border-b border-terminal-green hover:bg-terminal-green hover:text-terminal-black"
            >
              <td>{(currentPage - 1) * itemsPerPage + index + 1}</td>
              <td>{`${adventurer.name} - ${adventurer.id}`}</td>
              <td>
                <span className="flex justify-center text-terminal-yellow">
                  <Coin className="self-center w-6 h-6 fill-current" />
                  {adventurer.gold}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="flex justify-center mt-8">
        <Button variant={"outline"} onClick={() => handleClick(currentPage - 1)}>back</Button>
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
        <Button variant={"outline"} onClick={() => handleClick(currentPage + 1)}>next</Button>
      </div>
    </div>
  );
};

export default Leaderboard;
