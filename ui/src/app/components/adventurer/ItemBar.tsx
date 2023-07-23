import React from "react";
import { calculateLevel } from "../../lib/utils";

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

          <div className="flex space-x-2 relative">
            <span>{level}</span>
            <div className="w-full h-1 border border-black bg-terminal-green dark:bg-terminal-green self-center">
              <div className="flex justify-between text-xs sm:text-sm text-center absolute top-0 bg-terminal-green px-4 left-[30%]">
                {/* <span>Greatness</span> */}
              </div>
              <div
                className="h-full bg-black flex-grow  w-full"
                style={{ width: `${calculateProgress(xp)}%` }}
              ></div>
            </div>
            <span>{level + 1}</span>
          </div>

        </>
      )}
    </div>
  );
};

export default ItemBar;
