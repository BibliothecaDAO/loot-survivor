import { Button } from "@/app/components/buttons/Button";
import { ProfileIcon, TrophyIcon } from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";

export default function MobileHeader() {
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  return (
    <>
      <div className="flex flex-row justify-between items-center">
        <Button
          size="lg"
          onClick={() => setScreen("player")}
          variant={screen === "player" ? "default" : "ghost"}
        >
          <div className="flex flex-row items-center gap-2">
            <div className="relative flex items-center w-6 h-5">
              <ProfileIcon className="fill-current" />
            </div>
            <p>Profile</p>
          </div>
        </Button>
        <Button
          size="lg"
          onClick={() => setScreen("leaderboard")}
          variant={screen === "leaderboard" ? "default" : "ghost"}
        >
          <div className="flex flex-row items-center gap-2">
            <div className="relative flex items-center w-6 h-5">
              <TrophyIcon className="fill-current" />
            </div>
            <p>Leaderboard</p>
          </div>
        </Button>
      </div>
    </>
  );
}
