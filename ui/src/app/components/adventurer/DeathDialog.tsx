import TwitterShareButton from "../buttons/TwitterShareButtons";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import { Button } from "../buttons/Button";
import useUIStore from "../../hooks/useUIStore";
import Image from "next/image";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { getRankFromList, getOrdinalSuffix } from "../../lib/utils";
import { appUrl } from "@/app/lib/constants";

export const DeathDialog = () => {
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const { data } = useQueriesStore();

  const rank = getRankFromList(
    adventurer?.id ?? 0,
    data.adventurersByXPQuery?.adventurers ?? []
  );
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);
  return (
    <>
      <div className="top-0 left-0 fixed text-center h-full w-full z-50">
        <Image
          src={"/scenes/intro/sculls.png"}
          alt="skull"
          className="absolute object-cover"
          fill
        />

        <div className="flex flex-col gap-4 sm:gap-10 items-center z-10 p-20 h-full">
          <div className="flex flex-col gap-2 items-center justify-center z-10 self-center ">
            <h1 className="text-red-500">YOU DIED!</h1>
            <span className="text-lg sm:text-2xl text-terminal-yellow">
              {deathMessage}
            </span>
            <p className="sm:text-2xl">
              {adventurer?.name} has died level {adventurer?.level} with{" "}
              {adventurer?.xp} XP, a valiant effort!
            </p>
            <p className="hidden sm:block sm:text-xl">
              Make sure to share your score. Continue the journey with another
              adventurer:{" "}
            </p>
          </div>
          <TwitterShareButton
            text={`RIP ${adventurer?.name}, who died at ${ordinalRank} place on the #LootSurvivor leaderboard.\n\nThink you can beat ${adventurer?.xp} XP? Enter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
          />
          <Button
            onClick={() => {
              showDeathDialog(false);
              setDeathMessage(null);
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
