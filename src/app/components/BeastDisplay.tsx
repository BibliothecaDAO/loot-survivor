import Image from "next/image";
import { getValueFromKey } from "../lib/utils";
import { GameData } from "./GameData";

interface BeastDisplayProps {
  beastData: any;
}

export const BeastDisplay = ({ beastData }: BeastDisplayProps) => {
  const gameData = new GameData();
  return (
    <div className="flex flex-col">
      <div className="w-[250px] h-[250px] relative mt-4">
        <Image
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
            "/phoenix.png"
          }
          alt="beast-image"
          fill={true}
          style={{ objectFit: "contain" }}
        />
      </div>
      <div className="flex flex-col items-center mt-9">
        <div className="text-xl font-medium text-white">{beastData?.beast}</div>
        <p className="text-lg text-terminal-green">
          HEALTH {beastData?.health}
        </p>
        <p className="text-lg text-terminal-yellow">RANK {beastData?.rank}</p>
        <p className="text-lg text-terminal-yellow">LEVEL {beastData?.level}</p>
        <p className="text-lg text-terminal-yellow">XP {beastData?.xp}</p>
        <p className="text-lg text-red-600">{beastData?.attackType}</p>
        <p className="text-lg text-red-600">{beastData?.armorType}</p>
      </div>
    </div>
  );
};
