import Image from "next/image";
import { getValueFromKey } from "../lib/utils";
import { GameData } from "./GameData";
import { ANSIArt } from "./ANSIGenerator";
import Heart from "../../../public/heart.svg";
import Weapon from "../../../public/icons/loot/weapon.svg";
import Head from "../../../public/icons/loot/head.svg";
import Hand from "../../../public/icons/loot/hand.svg";
import Chest from "../../../public/icons/loot/chest.svg";
import Waist from "../../../public/icons/loot/waist.svg";
import Foot from "../../../public/icons/loot/foot.svg";

interface BeastDisplayProps {
  beastData: any;
}

const getAttackLocationIcon = (beastType: string) => {
  const gameData = new GameData();
  const iconPath = gameData.BEAST_ATTACK_LOCATION[beastType];
  if (!iconPath) return null;

  if (iconPath == "/icons/loot/hand.svg")
    return <Hand className="self-center w-8 h-8 fill-current mr-2" />;
  if (iconPath == "/icons/loot/chest.svg")
    return <Chest className="self-center w-8 h-8 fill-current mr-2" />;
  if (iconPath == "/icons/loot/waist.svg")
    return <Waist className="self-center w-8 h-8 fill-current mr-2" />;
  if (iconPath == "/icons/loot/foot.svg")
    return <Foot className="self-center w-8 h-8 fill-current mr-2" />;
  if (iconPath == "/icons/loot/head.svg")
    return <Head className="self-center w-8 h-8 fill-current mr-2" />;
};

export const BeastDisplay = ({ beastData }: BeastDisplayProps) => {
  const gameData = new GameData();
  const ansiImage = ANSIArt({
    imageUrl:
      getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
      "/beasts/phoenix.png",
    newWidth: 20,
  });
  return (
    <div className="flex flex-col h-full bg-black justify-center border-2 border-terminal-green transition-all duration-200 ease-in transform hover:-translate-y-1 hover:scale-105">
      <div className="flex items-center justify-center w-full">
        <ANSIArt
          newWidth={250}
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
            "/beasts/phoenix.png"
          }
        />
      </div>
      <div className="flex flex-col w-full p-2 uppercase">
        <div className="flex justify-between w-full text-4xl border-b border-terminal-green">
          {beastData?.beast}

          <span
            className={`text-4xl flex ${
              beastData?.health === 0 ? "text-red-600" : "text-terminal-green"
            }`}
          >
            <Heart className="self-center w-8 h-8 fill-current" />{" "}
            <p className="text-4xl">{beastData?.health}</p>
          </span>
        </div>
        <div className="flex justify-between">
          <p className="text-2xl text-terminal-yellow">
            Level {beastData?.level}
          </p>
          <p className="text-2xl text-terminal-yellow">XP {beastData?.xp}</p>
          <p className="text-2xl text-terminal-yellow">
            Tier {beastData?.rank}
          </p>
        </div>
        <div className="flex flex-row m-6">
          <p className="flex items-center text-2xl text-red-600">
            <Weapon className="self-center w-8 h-8 fill-current mr-2" />
            {beastData?.attackType}
          </p>
          <p className="flex items-center text-2xl text-red-600 ">
            {getAttackLocationIcon(beastData?.beast)}
            Attacks {beastData?.attackLocation}
          </p>
          <p className="flex items-center text-2xl text-red-600 ">
            {" "}
            <Head className="self-center w-8 h-8 fill-current text-red-600 mr-2" />
            {beastData?.armorType}
          </p>
        </div>
      </div>
    </div>
  );
};
