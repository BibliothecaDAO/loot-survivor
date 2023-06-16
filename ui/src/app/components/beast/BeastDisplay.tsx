import Image from "next/image";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { getValueFromKey } from "../../lib/utils";
import { GameData } from "../GameData";
import Heart from "../../../../public/heart.svg";
import Head from "../../../../public/icons/loot/head.svg";
import Hand from "../../../../public/icons/loot/hand.svg";
import Chest from "../../../../public/icons/loot/chest.svg";
import Waist from "../../../../public/icons/loot/waist.svg";
import Foot from "../../../../public/icons/loot/foot.svg";
import EfficacyIcon from "../EfficacyIcon";
import { processBeastName } from "../../lib/utils";

interface BeastDisplayProps {
  beastData: any;
  lastBattle: any;
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

export const BeastDisplay = ({ beastData, lastBattle }: BeastDisplayProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const gameData = new GameData();
  console.log(lastBattle);
  // const ansiImage = ANSIArt({
  //   imageUrl:
  //     getValueFromKey(gameData.BEAST_IMAGES, beastData?.beast) ||
  //     "/monsters/phoenix.png",
  //   newWidth: 20,
  // });

  const beastName = processBeastName(beastData);

  // if (beastData?.health === 0) {
  //   return (
  //     <div className="relative w-full h-full overflow-hidden border-2 border-terminal-green">
  //       <div className="absolute inset-0">
  //         <Image
  //           src={"/labyrinth.png"}
  //           alt="labyrinth"
  //           fill={true}
  //           style={{ objectFit: "cover" }}
  //           quality={100}
  //         />
  //       </div>
  //       <div className="relative flex flex-col items-center justify-center p-1 border border-terminal-green bg-terminal-black">
  //         <p className="text-2xl text-center">
  //           You have killed the beast! <br /> You survive...for now!
  //         </p>
  //       </div>
  //     </div>
  //   );
  // }

  return (
    <div className="relative flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">
      <div className="flex flex-col w-full h-full p-3 uppercase">
        <div className="flex justify-between py-3 text-2xl sm:text-4xl border-b border-terminal-green">
          {beastName}
          <span
            className={`text-4xl flex ${
              beastData?.health === 0 ? "text-red-600" : "text-terminal-green"
            }`}
          >
            <Heart className="self-center w-6 h-6 fill-current" />{" "}
            <p className="self-center text-2xl sm:text-4xl">
              {beastData?.health}
            </p>
          </span>
        </div>
        <div className="flex justify-between w-full py-2 ">
          <p className="text-xl sm:text-3xl text-terminal-yellow">
            Level {beastData?.level}
          </p>
          {/* <p className="text-3xl text-terminal-yellow">XP {beastData?.xp}</p> */}
          <p className="text-xl sm:text-3xl text-terminal-yellow">
            Tier {beastData?.rank}
          </p>
        </div>
        <div className="flex flex-row justify-center items-center w-full py-4 space-x-2">
          <div className="flex flex-row gap-2 items-center ml-5">
            <EfficacyIcon
              type={beastData?.attackType}
              size="w-6"
              className="self-center w-6 h-6"
            />
            <p className="text-sm text-center sm:text-xl">
              {beastData?.attackType}
            </p>
          </div>
          <div className="flex flex-row gap-2 items-center">
            {getAttackLocationIcon(beastData?.beast)}
            <p className="text-sm text-center sm:text-xl">
              Attacks {beastData?.attackLocation}
            </p>
          </div>
          <div className="flex flex-row gap-2 items-center">
            <EfficacyIcon
              type={beastData?.armorType}
              size="w-6"
              className="self-center w-6 h-6"
            />
            <p className="text-sm text-center sm:text-xl">
              {beastData?.armorType}
            </p>
          </div>
        </div>
      </div>
      <div className="relative flex-grow w-full h-40 sm:h-full pb-full">
        <Image
          src={
            getValueFromKey(gameData.BEAST_IMAGES, beastData?.beast) ||
            "/monsters/phoenix.png"
          }
          alt="monsters"
          fill={true}
          style={{
            objectFit: "contain",
            position: "absolute",
            width: "100%",
            height: "100%",
          }}
        />
      </div>
      {beastData?.health === 0 && (
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{ backdropFilter: "blur(1px)" }}
        >
          <p className="text-6xl font-bold text-red-600 uppercase">DEFEATED</p>
        </div>
      )}
      {lastBattle?.fled && (
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{ backdropFilter: "blur(1px)" }}
        >
          <p className="text-6xl font-bold text-terminal-yellow uppercase">
            FLED
          </p>
        </div>
      )}
    </div>
  );
};
