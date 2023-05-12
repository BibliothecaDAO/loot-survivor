import TwitterShareButton from "./TwitterShareButtons";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { Button } from "./Button";
import useUIStore from "../hooks/useUIStore";
import Image from "next/image";

export const DeathDialog = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const showDialog = useUIStore((state) => state.showDialog);
  const appUrl = "https://loot-survivor.vercel.app/";
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed top-1/4 left-1/4 w-1/2 h-1/2 rounded-lg border border-terminal-green bg-terminal-black z-50">
        <div className="flex flex-col gap-10 h-full items-center justify-center	p-10">
          <div className="relative w-full h-1/4">
            <Image
              src={"/skull.png"}
              alt="skull"
              fill={true}
              style={{ objectFit: "contain" }}
            />
          </div>
          <div className="flex flex-col gap-2 items-center justify-center">
            <p className="text-4xl">GAME OVER!</p>
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
            text={`RIP ${adventurer?.name}, who died at ${adventurer?.level}th place on the #LootSurvivor leaderboard.\n\nThink you can beat ${adventurer?.xp} XP? Enter here and try to survive: ${appUrl}\n\n@lootrealms #Starknet #Loot $Lords`}
          />
          <Button onClick={() => showDialog(false)}>Play Again</Button>
        </div>
      </div>
    </>
  );
};
