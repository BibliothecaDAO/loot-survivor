import React from "react";
import { calculateLevel } from "../../lib/utils";

interface ItemBarProps {
  xp: number;
}

const ItemBar: React.FC<ItemBarProps> = ({ xp }) => {
  const calculateProgress = (xp: number): number => {
    const currentLevelXP =
      calculateLevel(xp) > 1 ? Math.floor(calculateLevel(xp)) ** 2 : 0;
    const nextLevelXP = Math.floor(calculateLevel(xp) + 1) ** 2;

    return ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100;
  };
  let progress;
  const level = calculateLevel(xp);

  return (
    <div className="w-full text-black">
      {level >= 20 ? (
        <div>Max Greatness 20</div>
      ) : (
        <>
          <div className="flex justify-between text-xs sm:text-sm">
            <span>{level}</span>
            <span>Greatness</span>
            <span>{level + 1}</span>
          </div>
          <div className="w-full h-1 border border-black bg-terminal-green dark:bg-terminal-green ">
            <div
              className="h-full bg-black"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </>
      )}
    </div>
  );
};

export default ItemBar;
