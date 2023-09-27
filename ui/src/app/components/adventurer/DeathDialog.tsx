import React, { useEffect } from "react";
import TwitterShareButton from "../buttons/TwitterShareButtons";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import { Button } from "../buttons/Button";
import useUIStore from "../../hooks/useUIStore";
import Image from "next/image";
import { getRankFromList, getOrdinalSuffix } from "../../lib/utils";
import { appUrl } from "@/app/lib/constants";
import { getAdventurerByXP } from "@/app/hooks/graphql/queries";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { NullAdventurer, Adventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";

export const DeathDialog = () => {
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);

  const { data, refetch, setData } = useQueriesStore();

  useCustomQuery("adventurersByXPQuery", getAdventurerByXP, undefined);

  const handleSortXp = (xpData: any) => {
    const copiedAdventurersByXpData = xpData?.adventurers.slice();

    const sortedAdventurersByXPArray = copiedAdventurersByXpData?.sort(
      (a: Adventurer, b: Adventurer) => (b.xp ?? 0) - (a.xp ?? 0)
    );

    const sortedAdventurersByXP = { adventurers: sortedAdventurersByXPArray };
    return sortedAdventurersByXP;
  };

  const handleRank = () => {
    const sortedAdventurersByXP = data.adventurersByXPQuery;
    const rank = getRankFromList(
      adventurer?.id ?? 0,
      sortedAdventurersByXP?.adventurers ?? []
    );

    const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);
    return ordinalRank;
  };

  const rank = handleRank();

  useEffect(() => {
    refetch("adventurersByXPQuery", undefined)
      .then((adventurersByXPdata) => {
        const sortedAdventurersByXP = handleSortXp(adventurersByXPdata);
        setData("adventurersByXPQuery", sortedAdventurersByXP);
      })
      .catch((error) => console.error("Error refetching data:", error));
  }, []);

  console.log(data.adventurersByXPQuery);

  return (
    <>
      <div className="top-0 left-0 fixed text-center h-full w-full z-40">
        <Image
          src={"/scenes/intro/skulls.png"}
          alt="skull"
          className="absolute object-cover"
          fill
        />
        <div className="absolute inset-0 bg-black opacity-50"></div>

        <div className="flex flex-col gap-4 sm:gap-10 items-center justify-center z-10 p-20 h-full">
          <div className="flex flex-col gap-5 items-center justify-center z-10 self-center ">
            <h1 className="text-red-500 text-6xl">YOU DIED!</h1>
            <span className="text-lg sm:text-2xl text-terminal-yellow">
              {deathMessage}
            </span>
            <span className="flex flex-col gap-1 sm:text-2xl">
              <p>
                {adventurer?.name} died at {rank} on the leaderboard with{" "}
                {adventurer?.xp} XP, a valiant effort!
              </p>{" "}
              <p>
                Make sure to share your score. Continue the journey with another
                adventurer.
              </p>
            </span>
          </div>
          <TwitterShareButton
            text={`RIP ${adventurer?.name}, who died at ${rank} place on the #LootSurvivor leaderboard.\n\nThink you can beat ${adventurer?.xp} XP? Enter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
          />
          {/* <TwitterShareButton
            text={`RIP ${adventurer?.name}.\n\nThink you can beat ${adventurer?.xp} XP? Enter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
          /> */}
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
      </div>
    </>
  );
};
