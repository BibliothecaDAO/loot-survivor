import { Adventurer, Beast } from "@/app/types";
import BeastRow from "@/app/components/leaderboard/BeastRow";
import { getBeastData } from "@/app/lib/utils";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import {
  getKilledBeasts,
  getAdventurersInList,
} from "@/app/hooks/graphql/queries";
import useUIStore from "@/app/hooks/useUIStore";

const KilledBeastsTable = ({}) => {
  const network = useUIStore((state) => state.network);

  let previousDifficulty = -1;
  let currentRank = 0;
  let rankOffset = 0;

  const rankBeastDifficulty = (
    beast: Beast,
    index: number,
    rankOffset: number
  ) => {
    const { tier } = getBeastData(beast?.beast!);
    const difficulty = (6 - tier) * beast?.level!;

    if (difficulty !== previousDifficulty) {
      currentRank = index + 1;
      rankOffset = 0;
    } else {
      rankOffset++;
    }
    previousDifficulty = difficulty;
    return currentRank;
  };

  const killedBeastsData = useCustomQuery(
    network,
    "killedBeastsQuery",
    getKilledBeasts,
    undefined
  );

  const beasts: Beast[] = killedBeastsData?.beasts ?? [];

  const adventurersInListData = useCustomQuery(
    network,
    "adventurersInListQuery",
    getAdventurersInList,
    {
      ids: beasts?.map((beast) => beast.adventurerId!),
    }
  );

  const displayBeasts = beasts?.slice(0, 10);

  const mergedBeasts = displayBeasts.map((item1) => {
    const matchingItem2 = adventurersInListData?.adventurers.find(
      (item2: Adventurer) => item2.id === item1.adventurerId
    );

    return {
      ...item1,
      ...matchingItem2,
    };
  });

  return (
    <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row justify-between w-full">
      <div className="relative flex flex-col w-full sm:mr-4 flex-grow-2 p-2 gap-2">
        {beasts?.length > 0 ? (
          <>
            <h4 className="text-2xl text-center sm:text-2xl m-0">
              Pragma Beast Leaderboard
            </h4>
            <table className="w-full sm:text-lg xl:text-xl border border-terminal-green">
              <thead className="border border-terminal-green">
                <tr>
                  <th className="p-1">Rank</th>
                  <th className="p-1">Name</th>
                  <th className="p-1">Tier</th>
                  <th className="p-1">Level</th>
                  <th className="p-1">Power Rating</th>
                  <th className="p-1">Adventurer</th>
                </tr>
              </thead>
              <tbody>
                {mergedBeasts?.map((beast: any, index: number) => (
                  <BeastRow
                    key={index}
                    beast={beast}
                    rank={rankBeastDifficulty(beast, index, rankOffset)}
                  />
                ))}
              </tbody>
            </table>
          </>
        ) : (
          <h3 className="text-lg sm:text-2xl py-4">
            No beasts killed yet. Kill the first!
          </h3>
        )}
      </div>
    </div>
  );
};

export default KilledBeastsTable;
