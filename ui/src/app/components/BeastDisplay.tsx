import Image from "next/image";
import { getValueFromKey } from "../lib/utils";
import { GameData } from "./GameData";
import { ANSIArt } from "./ANSIGenerator";

interface BeastDisplayProps {
  beastData: any;
}

export const BeastDisplay = ({ beastData }: BeastDisplayProps) => {
  const gameData = new GameData();
  const ansiImage = ANSIArt({
    imageUrl:
      getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) || "/phoenix.png",
    newWidth: 20,
  });
  return (
    <div className="flex flex-col">
      <div className="w-[160px] h-[160px] border-4 border-white relative m-4">
        <Image
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
            "/phoenix.png"
          }
          alt="beast-image"
          fill={true}
          style={{ objectFit: "contain" }}
        />
        {/* {ansiImage} */}
      </div>
      <div className="flex flex-col items-center mt-5">
        <div className="text-xl font-medium text-white">{beastData?.beast}</div>
        <p
          className={`text-lg ${
            beastData?.health === 0
              ? "text-terminal-red"
              : "text-terminal-green"
          }`}
        >
          HEALTH {beastData?.health}
        </p>
        <p className="text-2xl text-terminal-yellow">RANK {beastData?.rank}</p>
        <p className="text-2xl text-terminal-yellow">
          LEVEL {beastData?.level}
        </p>
        <p className="text-2xl text-terminal-yellow">XP {beastData?.xp}</p>
        <p className="text-2xl text-red-600">{beastData?.attackType}</p>
        <p className="text-2xl text-red-600">{beastData?.armorType}</p>
      </div>
    </div>
  );
};
