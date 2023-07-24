import { Adventurer, NullAdventurer } from "../../types";
import { HeartIcon, CoinIcon } from "../icons/Icons";
import LevelBar from "./LevelBar";
import { getRealmNameById } from "../../lib/utils";

interface InfoProps {
  adventurer: Adventurer | undefined;
}

export default function TopInfo({ adventurer }: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;

  return (
    <>
      {adventurer?.id ? (
        <div className="h-full border border-terminal-green overflow-auto">
          <div className="flex flex-row flex-wrap gap-2 p-1">
            <div className="flex flex-col w-full sm:p-2 uppercase">
              <div className="flex justify-between w-full">
                {formatAdventurer.classType ?? 0}{" "}
                <span>
                  {
                    getRealmNameById(formatAdventurer.homeRealm ?? 0)
                      ?.properties.name
                  }
                </span>
                <span>
                  {
                    getRealmNameById(formatAdventurer.homeRealm ?? 0)
                      ?.properties.order
                  }
                </span>
              </div>
              <div className="flex justify-between w-full text-2xl sm:text-4xl font-medium border-b border-terminal-green">
                {formatAdventurer.name}
                <span className="flex text-terminal-yellow">
                  <CoinIcon className="self-center w-6 h-6 fill-current" />{" "}
                  {formatAdventurer.gold ? formatAdventurer.gold : 0}
                </span>
                <span className="flex ">
                  <HeartIcon className="self-center w-6 h-6 fill-current" />{" "}
                  {`${formatAdventurer.health ?? 0}/${
                    100 + (formatAdventurer.vitality ?? 0) * 20
                  }`}
                </span>
              </div>

              <div className="flex justify-between w-full text-lg sm:text-2xl">
                <LevelBar xp={formatAdventurer.xp ?? 0} />
              </div>
            </div>
            {/* {0 === 0 && (
          <div className="absolute w-full h-full flex items-center justify-center backdrop-blur-[1px]">
            <p className="text-6xl font-bold text-red-600 uppercase">DEAD</p>
          </div>
        )} */}
          </div>
        </div>
      ) : (
        <p className="text-2xl text-center">Choose an adventurer</p>
      )}
    </>
  );
}
