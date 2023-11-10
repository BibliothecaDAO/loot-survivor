import React, { useEffect, useState, useRef } from "react";
import TwitterShareButton from "@/app/components/buttons/TwitterShareButtons";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { getRankFromList, getOrdinalSuffix } from "@/app/lib/utils";
import { getAdventurerByXP } from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { NullAdventurer, Adventurer } from "@/app/types";
import { useQueriesStore, AdventurersResult } from "@/app/hooks/useQueryStore";
import GlitchEffect from "@/app/components/animations/GlitchEffect";
import PixelatedImage from "@/app/components/animations/PixelatedImage";
import { getDeathMessageByRank } from "@/app/lib/utils";

export const DeathDialog = () => {
  const messageRef = useRef<HTMLSpanElement>(null);
  const [rank, setRank] = useState<number | null>(null);
  const [twitterDeathMessage, setTwitterDeathMessage] = useState<
    string | undefined
  >();
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const [imageLoading, setImageLoading] = useState(false);

  const { refetch, setData } = useQueriesStore();

  useCustomQuery("adventurersByXPQuery", getAdventurerByXP, undefined);

  const handleSortXp = (xpData: AdventurersResult) => {
    const copiedAdventurersByXpData = xpData?.adventurers.slice();

    const sortedAdventurersByXPArray = copiedAdventurersByXpData?.sort(
      (a: Adventurer, b: Adventurer) => (b.xp ?? 0) - (a.xp ?? 0)
    );

    const sortedAdventurersByXP = { adventurers: sortedAdventurersByXPArray };
    return sortedAdventurersByXP;
  };

  useEffect(() => {
    refetch("adventurersByXPQuery", undefined)
      .then((adventurersByXPdata) => {
        const sortedAdventurersByXP = handleSortXp(adventurersByXPdata);
        setData("adventurersByXPQuery", sortedAdventurersByXP);
        const rank = getRankFromList(
          adventurer?.id ?? 0,
          sortedAdventurersByXP?.adventurers ?? []
        );
        setRank(rank + 1);
      })
      .catch((error) => console.error("Error refetching data:", error));
  }, []);

  useEffect(() => {
    setTwitterDeathMessage(messageRef.current?.innerText);
  }, [messageRef.current]);

  return (
    <>
      {rank && (
        <div className="top-0 left-0 fixed text-center h-full w-full z-40">
          <PixelatedImage
            src={"/scenes/intro/skulls.png"}
            pixelSize={rank <= 100 ? 10 : 20}
            setImageLoading={setImageLoading}
            fill={true}
          />

          <div className="absolute inset-0 bg-black opacity-50"></div>

          {!imageLoading && (
            <div className="flex flex-col gap-4 sm:gap-10 items-center justify-center z-10 p-10 sm:p-20 h-full">
              <div className="flex flex-col gap-5 items-center justify-center z-10 self-center ">
                {rank! <= 3 &&
                  rank! > 0 &&
                  (rank === 1 ? (
                    <h1 className="text-6xl animate-pulseFast">
                      NEW HIGH SCORE
                    </h1>
                  ) : (
                    <h1 className="text-6xl animate-pulseFast">TOP 3 SCORES</h1>
                  ))}
                {rank! <= 50 ? (
                  <GlitchEffect />
                ) : (
                  <h1 className="text-red-500 text-6xl">YOU DIED!</h1>
                )}
                <span
                  ref={messageRef}
                  className="text-lg sm:text-3xl text-red-500"
                >
                  {deathMessage}
                </span>
                <span className="flex flex-col gap-2 text-lg sm:text-4xl">
                  <span className="text-terminal-yellow">
                    {getDeathMessageByRank(rank!)}
                  </span>{" "}
                  <span className="text-4xl">
                    <span className="text-terminal-yellow">
                      {adventurer?.name}
                    </span>{" "}
                    died{" "}
                    <span className="text-terminal-yellow">
                      {getOrdinalSuffix(rank! ?? 0)}
                    </span>{" "}
                    with{" "}
                    <span className="text-terminal-yellow">
                      {adventurer?.xp} XP
                    </span>
                  </span>
                </span>
                <span className="sm:text-2xl">
                  Share your score. Continue the journey with another
                  adventurer.
                </span>
              </div>
              <TwitterShareButton
                text={`RIP ${adventurer?.name}, who died at ${getOrdinalSuffix(
                  rank! ?? 0
                )} place on #LootSurvivor with ${
                  adventurer?.xp
                } XP.\n\nGravestone bears the inscription:\n\n"${twitterDeathMessage}"🪦\n\nEnter here and try to survive: ${
                  process.env.NEXT_PUBLIC_APP_URL
                }\n\n@lootrealms #Starknet #Play2Die #🪦`}
                className="animate-pulse"
              />
              <Button
                onClick={() => {
                  showDeathDialog(false);
                  setDeathMessage(null);
                  setAdventurer(NullAdventurer);
                }}
                className="z-10"
              >
                Play Again
              </Button>
            </div>
          )}
        </div>
      )}
    </>
  );
};
