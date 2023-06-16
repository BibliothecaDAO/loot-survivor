import TwitterShareButton from "./buttons/TwitterShareButtons";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useLoadingStore from "../hooks/useLoadingStore";
import { Button } from "./buttons/Button";
import useUIStore from "../hooks/useUIStore";
import Image from "next/image";
import { useQueriesStore } from "../hooks/useQueryStore";
import { getRankFromList, getOrdinalSuffix } from "../lib/utils";

export const DeathDialog = () => {
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const showDialog = useUIStore((state) => state.showDialog);
  const appUrl = "https://loot-survivor.vercel.app/";
  const { data } = useQueriesStore();

  const rank = getRankFromList(
    adventurer?.id ?? 0,
    data.adventurersByXPQuery?.adventurers ?? []
  );
  const ordinalRank = getOrdinalSuffix(rank + 1 ?? 0);
  console.log(deathMessage);
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed top-1/8 left-1/4 w-1/2 h-3/4 rounded-lg border border-red-500 bg-terminal-black z-50">
        <div className="flex flex-col gap-10 h-full items-center justify-center	p-5">
          <div className="relative w-full h-1/2">
            <Image
              src={"/crying-skull.png"}
              alt="skull"
              fill={true}
              style={{ objectFit: "contain" }}
            />
          </div>
          <div className="flex flex-col gap-2 items-center justify-center">
            <p className="text-4xl text-red-500">GAME OVER!</p>
            {deathMessage}
            <p className="text-2xl">
              {adventurer?.name} has died level {adventurer?.level} with{" "}
              {adventurer?.xp} xp, a valiant effort!
            </p>
            <p className="text-xl">
              Make sure to share your score. Continue the journey with another
              adventurer:{" "}
            </p>
          </div>
          <TwitterShareButton
            text={`RIP ${adventurer?.name}, who died at ${ordinalRank} place on the #LootSurvivor leaderboard.\n\nThink you can beat ${adventurer?.xp} XP? Enter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Play2Die #LootSurvivor`}
          />
          <Button
            onClick={() => {
              showDialog(false);
              setDeathMessage(null);
            }}
          >
            Play Again
          </Button>
        </div>
      </div>
    </>
  );
};
