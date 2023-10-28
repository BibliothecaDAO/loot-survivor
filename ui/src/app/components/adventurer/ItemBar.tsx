import React from "react";
import { calculateLevel } from "@/app/lib/utils";

interface ItemBarProps {
  xp: number;
}

const calculateProgress = (xp: number): number => {
  const currentLevelXP =
    calculateLevel(xp) > 1 ? Math.floor(calculateLevel(xp)) ** 2 : 0;
  const nextLevelXP = Math.floor(calculateLevel(xp) + 1) ** 2;

  return ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100;
};

const ItemBar: React.FC<ItemBarProps> = ({ xp }) => {
  const level = calculateLevel(xp);

  return (
    <div className="w-full text-black">
      {level >= 20 ? (
        <div className="text-bold">Max Greatness 20</div>
      ) : (
        <>
          <div className="flex flex-row h-1 items-center gap-2 relative mt-2">
            <span className="text-sm">{level}</span>
            <span className="w-full flex flex-col self-center mb-2">
              <span className="text-xs text-center">{xp} XP</span>
              <div className="w-full h-1 border border-black bg-terminal-green dark:bg-terminal-green">
                <div
                  className="h-full bg-black flex-grow w-full"
                  style={{ width: `${calculateProgress(xp)}%` }}
                />
              </div>
            </span>
            <span className="text-sm">{level + 1}</span>
          </div>
        </>
      )}
    </div>
  );
};

export default ItemBar;
