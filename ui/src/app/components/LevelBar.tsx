import React from "react";

interface LevelBarProps {
  xp: number;
  level: number;
}

const calculateProgress = (xp: number, level: number): number => {
  const currentLevelXP = Math.floor(((level - 1) * 10) / 3) ** 2;
  const nextLevelXP = Math.floor((level * 10) / 3) ** 2;

  return ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100;
};

const LevelBar: React.FC<LevelBarProps> = ({ xp, level }) => {
  const progress = calculateProgress(xp, level);

  return (
    <div className="w-full py-2 text-2xl text-terminal-green">
      <div className="flex justify-between">
        <span>Level {level}</span>
        <span>XP {xp}</span>
        <span>Level {level + 1}</span>
      </div>
      <div className="w-full h-2 mt-1 border border-terminal-green bg-terminal-black ">
        <div
          className="h-full bg-terminal-green animate-pulse"
          style={{ width: `${progress}%` }}
        ></div>
      </div>
    </div>
  );
};

export default LevelBar;
