import Image from "next/image";
import { getValueFromKey } from "../lib/utils";
import { GameData } from "./GameData";
import { ANSIArt } from "./ANSIGenerator";
import Heart from "../../../public/heart.svg";
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
    <div className="flex w-full p-1 border border-terminal-green">
      <div>
        <ANSIArt
          newWidth={240}
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
            "/phoenix.png"
          }
        />
      </div>
      <div className="flex flex-col w-full p-2">
        <div className="flex justify-between w-full text-2xl border-b border-terminal-green">
          {beastData?.beast}

          <span
            className={`text-2xl flex ${
              beastData?.health === 0 ? "text-red-600" : "text-terminal-green"
            }`}
          >
            <Heart className="self-center w-6 h-6 fill-current" />{" "}
            {beastData?.health}
          </span>
        </div>
        <div className="flex justify-between">
          <p className="text-2xl text-terminal-yellow">
            Level {beastData?.level}
          </p>
          <p className="text-2xl text-terminal-yellow">XP {beastData?.xp}</p>
          <p className="text-2xl text-terminal-yellow">
            Rank {beastData?.rank}
          </p>
        </div>

        <p className="text-2xl text-red-600">{beastData?.attackType}</p>
        <p className="text-2xl text-red-600">{beastData?.attackLocation}</p>
        <p className="text-2xl text-red-600">{beastData?.armorType}</p>
      </div>
    </div>
  );
};
