import { useState } from "react";
import { Button } from "../buttons/Button";
import { ControllerIcon, TrophyIcon } from "../icons/Icons";
import useUIStore from "../../hooks/useUIStore";
import { capitalizeFirstLetter } from "../../lib/utils";

export default function MobileHeader() {
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  return (
    <>
      <div className="flex flex-row justify-between items-center">
        <Button
          onClick={() => setScreen("player")}
          variant={screen === "player" ? "default" : "ghost"}
        >
          <div className="flex flex-row items-center gap-2">
            <div className="flex items-center w-6 h-6">
              <ControllerIcon />
            </div>
            <p>Profile</p>
          </div>
        </Button>
        <div className="absolute left-1/2 right-1/2 flex justify-center">
          <h2 className="text-xl m-0">
            {screen == "player"
              ? "Profile"
              : capitalizeFirstLetter(screen ?? "")}
          </h2>
        </div>
        <Button
          onClick={() => setScreen("leaderboard")}
          variant={screen === "leaderboard" ? "default" : "ghost"}
        >
          <div className="flex flex-row items-center gap-2">
            <div className="flex items-center w-6 h-6">
              <TrophyIcon />
            </div>
            <p>Leaderboard</p>
          </div>
        </Button>
      </div>
    </>
  );
}
