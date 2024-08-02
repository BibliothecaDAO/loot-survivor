import { useEffect, useState } from "react";
import Hints from "@/app/components/interlude/Hints";
import { EntropyCountDown } from "@/app/components/CountDown";
import useAdventurerStore from "../hooks/useAdventurerStore";

interface InterludeScreenProps {
  type: string;
}

export default function InterludeScreen({ type }: InterludeScreenProps) {
  const [countDownExpired, setCountDownExpired] = useState(false);
  const [nextEntropyTime, setNextEntropyTime] = useState<number | null>(null);
  const adventurer = useAdventurerStore((state) => state.adventurer);

  useEffect(() => {
    const currentTime = new Date().getTime();
    setNextEntropyTime(currentTime + 15 * 1000);
  }, []);
  return (
    <>
      <div className="fixed inset-0 left-0 right-0 bottom-0 opacity-80 bg-terminal-black z-40 sm:m-2 w-full h-full" />
      <div className="fixed inset-0 z-40 w-full h-full sm:py-8 2xl:py-20">
        <div className="h-1/4 flex items-center justify-center">
          <span className="flex flex-col gap-1 items-center justify-center">
            <p className="text-2xl">
              {type === "level"
                ? `Generating Verifiable Randomness for Level ${adventurer?.level}`
                : "Generating Verifiable Randomness for Item Unlocks"}
            </p>
            {!countDownExpired ? (
              <EntropyCountDown
                targetTime={nextEntropyTime}
                countDownExpired={() => setCountDownExpired(true)}
              />
            ) : (
              <p className="text-6xl animate-pulse text-terminal-yellow">
                Please wait
              </p>
            )}
          </span>
        </div>
        <div className="flex justify-center items-center h-3/4">
          <Hints />
        </div>
      </div>
    </>
  );
}
