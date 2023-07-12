import Image from "next/image";
import { getBeastData } from "../../lib/utils";
import { HeartIcon } from "../icons/Icons";
import EfficacyIcon from "../icons/EfficacyIcon";
import { processBeastName } from "../../lib/utils";
import { Battle, Discovery, Adventurer } from "@/app/types";

interface BeastDisplayProps {
  beastData: Discovery;
  lastBattle: Battle;
  adventurer: Adventurer;
}

export const BeastDisplay = ({
  beastData,
  lastBattle,
  adventurer,
}: BeastDisplayProps) => {
  const beastName = processBeastName(
    beastData?.entity ?? "",
    beastData?.special2 ?? "",
    beastData?.special3 ?? ""
  );
  const { tier, attack, armor, image } = getBeastData(beastData?.entity ?? "");

  console.log(beastData)
  return (
    <div className="relative flex flex-col items-center h-full overflow-hidden border-2 border-terminal-green">
      <div className="flex flex-col w-full h-full p-3 uppercase">
        <div className="flex justify-between py-3 text-2xl sm:text-4xl border-b border-terminal-green">
          {beastName}
          <span
            className={`text-4xl flex ${
              beastData?.entityHealth === 0
                ? "text-red-600"
                : "text-terminal-green"
            }`}
          >
            <HeartIcon className="self-center w-6 h-6 fill-current" />{" "}
            <p className="self-center text-2xl sm:text-4xl">
              {beastData?.entityHealth}
            </p>
          </span>
        </div>
        <div className="flex justify-between w-full py-2 ">
          <p className="text-xl sm:text-3xl text-terminal-yellow">
            Level {beastData?.entityLevel}
          </p>
          {/* <p className="text-3xl text-terminal-yellow">XP {beastData?.xp}</p> */}
          <p className="text-xl sm:text-3xl text-terminal-yellow">
            Tier {tier}
          </p>
        </div>
        <div className="flex flex-row justify-center gap-4 items-center w-full py-4 space-x-2">
          <div className="flex flex-row gap-2 items-center ml-5">
            <EfficacyIcon
              type={attack}
              size="w-6"
              className="self-center w-6 h-6"
            />
            <p className="text-sm text-center sm:text-xl">{attack} Attack</p>
          </div>
          <div className="flex flex-row gap-2 items-center">
            <EfficacyIcon
              type={armor}
              size="w-6"
              className="self-center w-6 h-6"
            />
            <p className="text-sm text-center sm:text-xl">{armor} Armor</p>
          </div>
        </div>
      </div>
      <div className="relative flex-grow w-full h-40 sm:h-[150%]">
        <Image
          src={image}
          alt="monsters"
          fill={true}
          style={{
            objectFit: "contain",
          }}
        />
      </div>
      {adventurer?.health === 0 && (
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
