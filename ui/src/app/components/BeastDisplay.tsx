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
    return <Hand className="self-center w-6 h-6 fill-current" />;
  if (iconPath == "/icons/loot/chest.svg")
    return <Chest className="self-center w-6 h-6 fill-current" />;
  if (iconPath == "/icons/loot/waist.svg")
    return <Waist className="self-center w-6 h-6 fill-current" />;
  if (iconPath == "/icons/loot/foot.svg")
    return <Foot className="self-center w-6 h-6 fill-current" />;
  if (iconPath == "/icons/loot/head.svg")
    return <Head className="self-center w-6 h-6 fill-current" />;
};

export const BeastDisplay = ({ beastData }: BeastDisplayProps) => {
  if (beastData?.health === 0) {
    return (
      <div className="relative w-full h-full overflow-hidden border-2 border-terminal-green">
        <div className="absolute inset-0">
          <Image
            src={"/labyrinth.png"}
            alt="labyrinth"
            fill={true}
            style={{ objectFit: "cover" }}
            quality={100}
          />
        </div>
        <div className="relative flex flex-col items-center justify-center p-1 border border-terminal-green bg-terminal-black">
          <p className="text-2xl text-center">
            You have killed the beast and made it out of the Labyrinth!
          </p>
        </div>
      </div>
    );
  }
  const gameData = new GameData();
  const ansiImage = ANSIArt({
    imageUrl:
      getValueFromKey(gameData.BEAST_IMAGES, beastData?.beast) ||
      "/monsters/phoenix.png",
    newWidth: 20,
  });
  return (
    <div className="flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">

      <div className="flex flex-col w-full p-3 py-2 uppercase">
        <div className="flex justify-between py-2 text-4xl border-b border-terminal-green">
          {beastData?.beast}

          <span
            className={`text-4xl flex ${beastData?.health === 0 ? "text-red-600" : "text-terminal-green"
              }`}
          >
            <Heart className="self-center w-6 h-6 fill-current" />{" "}
            {beastData?.health === 0 ? (
              <p className="text-sm">dead!</p>
            ) : (
              <p className="text-4xl">{beastData?.health}</p>
            )}
          </span>
        </div>
        <div className="flex justify-between w-full py-2 ">
          <p className="text-3xl text-terminal-yellow">
            Level {beastData?.level}
          </p>
          <p className="text-3xl text-terminal-yellow">XP {beastData?.xp}</p>
          <p className="text-3xl text-terminal-yellow">
            Tier {beastData?.rank}
          </p>
        </div>
        <div className="flex flex-row w-full py-4 space-x-2">
          <div className="flex flex-row gap-2">
            <Weapon className="self-center w-6 h-6 fill-current" />
            <p className="flex items-center text-xl">{beastData?.attackType}</p>
          </div>
          <div className="flex flex-row gap-2">
            {getAttackLocationIcon(beastData?.beast)}
            <p className="flex items-center text-xl">
              Attacks {beastData?.attackLocation}
            </p>
          </div>
          <div className="flex flex-row gap-2">
            <Chest className="self-center w-6 h-6 fill-current" />
            <p className="flex items-center text-xl">{beastData?.armorType}</p>
          </div>
        </div>
      </div>
      <div className="relative flex w-full h-full">
        <Image
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData.beast) ||
            "/monsters/phoenix.png"
          }
          alt="monsters"
          fill={true}
          style={{ objectFit: "contain" }}
        ></Image>
      </div>
    </div>
  );
};
