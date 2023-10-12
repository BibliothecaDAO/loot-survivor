import { useState, useEffect } from "react";
import { useBlock } from "@starknet-react/core";
import { EntropyCountDown } from "../components/CountDown";
import Hints from "../components/interlude/Hints";
import { fetchAverageBlockTime } from "../lib/utils";
import useAdventurerStore from "../hooks/useAdventurerStore";

export default function InterludeScreen() {
  const { adventurer } = useAdventurerStore();
  const [fetchedAverageBlockTime, setFetchedAverageBlockTime] = useState(false);
  const [averageBlockTime, setAverageBlockTime] = useState(0);
  const [nextEntropyTime, setNextEntropyTime] = useState<number | null>(null);
  const [countDownExpired, setCountDownExpired] = useState(false);

  const { data: blockData } = useBlock({
    refetchInterval: false,
  });

  const fetchData = async () => {
    const result = await fetchAverageBlockTime(blockData?.block_number!, 10);
    setAverageBlockTime(result!);
    setFetchedAverageBlockTime(true);
  };

  const getNextEntropyTime = () => {
    const nextBlockHashBlock = adventurer?.revealBlock!;
    const adventurerStartBlock = adventurer?.startBlock!;
    const blockDifference = nextBlockHashBlock - adventurerStartBlock;
    const secondsUntilNextEntropy = blockDifference * averageBlockTime;
    const adventurerCreatedTime = new Date(adventurer?.createdTime!).getTime();
    const nextEntropyTime =
      adventurerCreatedTime + secondsUntilNextEntropy * 1000;
    setNextEntropyTime(nextEntropyTime);
  };

  useEffect(() => {
    if (fetchedAverageBlockTime) {
      getNextEntropyTime();
    } else {
      fetchData();
    }
  }, [fetchedAverageBlockTime]);

  return (
    <>
      {!countDownExpired && (
        <>
          <div className="fixed inset-0 left-0 right-0 bottom-0 opacity-80 bg-terminal-black z-40 m-2 w-full h-full" />
          <div className="fixed inset-0 z-50 w-full h-full py-20">
            <EntropyCountDown
              targetTime={nextEntropyTime}
              countDownExpired={() => setCountDownExpired(true)}
            />
            <div className="flex justify-center items-center h-3/4">
              <Hints />
            </div>
          </div>
        </>
      )}
    </>
  );
}