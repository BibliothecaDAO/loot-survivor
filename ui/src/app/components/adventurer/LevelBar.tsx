import React from "react";
import { calculateLevel } from "@/app/lib/utils";

interface LevelBarProps {
  xp: number;
}

const calculateProgress = (xp: number): number => {
  const currentLevelXP =
    calculateLevel(xp) > 1 ? Math.floor(calculateLevel(xp)) ** 2 : 0;
  const nextLevelXP = Math.floor(calculateLevel(xp) + 1) ** 2;

  return ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100;
};

const LevelBar: React.FC<LevelBarProps> = ({ xp }) => {
  const progress = calculateProgress(xp);
  const level = calculateLevel(xp);

  return (
    <div className="w-full sm:py-2 text-terminal-green">
      <div className="flex justify-between">
        <span>Lvl {level}</span>
        <span>XP {xp}</span>
        <span>Lvl {level + 1}</span>
      </div>
      <div className="w-full h-2 sm:mt-1 border border-terminal-green bg-terminal-black ">
        <div
          className="h-full bg-terminal-green"
          style={{ width: `${progress}%` }}
        ></div>
      </div>
    </div>
  );
};

export default LevelBar;
