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
    <div className="text-terminal-green text-2xl p-4 rounded w-full">
      <div className="flex justify-between">
        <span>Level {level}</span>
        <span>XP {xp}</span>
        <span>Level {level + 1}</span>
      </div>
      <div className="h-2 w-full bg-terminal-black mt-2 rounded border border-slate-500">
        <div
          className="h-full bg-terminal-green"
          style={{ width: `${progress}%` }}
        ></div>
      </div>
    </div>
  );
};

export default LevelBar;
