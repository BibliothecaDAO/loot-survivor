import TwitterShareButton from "./TwitterShareButton";
import useAdventurerStore from "../hooks/useAdventurerStore";

export const DeathDialog = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  return (
    <>
      <div className="fixed top-0 left-0 right-0 bottom-0 opacity-80 bg-terminal-black z-2" />
      <div className="fixed w-1/2 h-3/4 rounded-lg border border-terminal-green bg-terminal-black z-3">
        <div className="flex flex-col p-5 align-center justify-center">
          <TwitterShareButton
            url="https://loot-survivor.vercel.app"
            text={`I got a score of ${adventurer?.xp} xp on Loot Survivor. Come and dive into the labyrinth at`}
            via="lootrealms"
            hashtags={["loot", "realms"]}
          />
        </div>
      </div>
    </>
  );
};
