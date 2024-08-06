import React, { useEffect, useState, useRef, useMemo } from "react";
import ReactDOMServer from "react-dom/server"; // Import this to convert ReactElement to string
import TwitterShareButton from "@/app/components/buttons/TwitterShareButtons";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { getOrdinalSuffix } from "@/app/lib/utils";
import { getAdventurerRank } from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { NullAdventurer } from "@/app/types";
import GlitchEffect from "@/app/components/animations/GlitchEffect";
import PixelatedImage from "@/app/components/animations/PixelatedImage";
import { getDeathMessageByRank } from "@/app/lib/utils";
import { networkConfig } from "@/app/lib/networkConfig";

export const DeathDialog = () => {
  const messageRef = useRef<HTMLSpanElement>(null);
  const [twitterDeathMessage, setTwitterDeathMessage] = useState<
    string | undefined
  >();
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const setScreen = useUIStore((state) => state.setScreen);
  const network = useUIStore((state) => state.network);
  const [imageLoading, setImageLoading] = useState(false);

  const rankVariables = useMemo(
    () => ({ adventurerId: adventurer?.id, adventurerXp: adventurer?.xp }),
    [adventurer?.id, adventurer?.xp]
  );

  const adventurerRankData = useCustomQuery(
    network,
    "adventurerRankQuery",
    getAdventurerRank,
    rankVariables
  );

  const adventurerRank = adventurerRankData?.adventurerRank?.rank;

  // Utility function to strip HTML tags
  const stripHtmlTags = (html: string) => {
    const div = document.createElement("div");
    div.innerHTML = html;
    return div.textContent || div.innerText || "";
  };

  useEffect(() => {
    if (deathMessage) {
      const deathMessageString =
        ReactDOMServer.renderToStaticMarkup(deathMessage);
      const plainTextMessage = stripHtmlTags(deathMessageString);
      setTwitterDeathMessage(plainTextMessage);
    }
  }, [deathMessage]);

  return (
    <>
      {adventurerRank !== null && (
        <div className="top-0 left-0 fixed text-center h-full w-full z-40">
          <PixelatedImage
            src={"/scenes/intro/skulls.png"}
            pixelSize={adventurerRank <= 100 ? 10 : 20}
            setImageLoading={setImageLoading}
            fill={true}
          />

          <div className="absolute inset-0 bg-black opacity-50"></div>

          {!imageLoading && (
            <div className="flex flex-col gap-4 sm:gap-10 items-center justify-center z-10 p-10 sm:p-20 h-full">
              <div className="flex flex-col gap-5 items-center justify-center z-10 self-center ">
                {adventurerRank! <= 3 &&
                  adventurerRank! > 0 &&
                  (adventurerRank === 1 ? (
                    <h1 className="text-6xl animate-pulseFast">
                      NEW HIGH SCORE
                    </h1>
                  ) : (
                    <h1 className="text-6xl animate-pulseFast">TOP 3 SCORES</h1>
                  ))}
                {adventurerRank! <= 50 ? (
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
                    {getDeathMessageByRank(adventurerRank!)}
                  </span>{" "}
                  <span className="text-4xl">
                    <span className="text-terminal-yellow">
                      {adventurer?.name}
                    </span>{" "}
                    died{" "}
                    <span className="text-terminal-yellow">
                      {getOrdinalSuffix(adventurerRank! ?? 0)}
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
                  adventurerRank! ?? 0
                )} place on #LootSurvivor with ${
                  adventurer?.xp
                } XP.\n\n"${twitterDeathMessage}"🪦\n\nEnter here and try to survive: ${
                  networkConfig[network!].appUrl
                }\n\n@lootrealms @provablegames #LootSurvivor #Starknet`}
                className="animate-pulse"
              />
              <Button
                onClick={() => {
                  showDeathDialog(false);
                  setDeathMessage(null);
                  setAdventurer(NullAdventurer);
                  setScreen("leaderboard");
                }}
                className="z-10"
              >
                See Leaderboard
              </Button>
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
