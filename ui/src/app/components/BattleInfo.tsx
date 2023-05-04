import { NullAdventurer } from "../types";
import { useQuery } from "@apollo/client";
import { getItemsByAdventurer } from "../hooks/graphql/queries";
import { ANSIArt } from "./ANSIGenerator";
import Heart from "../../../public/heart.svg";
import Coin from "../../../public/coin.svg";
import Mike from "../../../public/MIKE.png";
import { ItemDisplay } from "./ItemDisplay";
import LevelBar from "./LevelBar";
interface BattleInfoProps {
  adventurer: any;
}

export default function BattleInfo({ adventurer }: BattleInfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const {
    loading: itemsByAdventurerLoading,
    error: itemsByAdventurerError,
    data: itemsByAdventurerData,
    refetch: itemsByAdventurerRefetch,
  } = useQuery(getItemsByAdventurer, {
    variables: {
      adventurer: formatAdventurer.id,
    },
    pollInterval: 5000,
  });

  const items = itemsByAdventurerData ? itemsByAdventurerData.items : [];

  return (
    <div className="flex flex-col h-full w-full bg-black justify-center border-4 border-terminal-green transition-all duration-200 ease-in transform hover:-translate-y-1 hover:scale-105">
      <div className="flex items-center justify-center w-full">
        <div className="flex flex-row gap-2 p-1">
          <div className="flex flex-col w-full p-2 uppercase ">
            <div className="flex justify-between w-full text-4xl font-medium border-b border-terminal-green">
              {formatAdventurer.name}
              <span className="flex text-terminal-yellow">
                <Coin className="self-center w-6 h-6 fill-current" />{" "}
                {formatAdventurer.gold}
              </span>
              <span className="flex ">
                <Heart className="self-center w-6 h-6 fill-current" />{" "}
                {formatAdventurer.health}
              </span>
            </div>
            <div className="flex justify-between w-full text-2xl">
              <LevelBar
                xp={formatAdventurer.xp}
                level={formatAdventurer.level}
              />
            </div>
            <div className="flex flex-row justify-between">
              <div className="flex flex-col">
                <div className="">
                  <ItemDisplay
                    type={"weapon"}
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.weaponId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="head"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.headId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="chest"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.chestId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="hands"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.handsId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="waist"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.waistId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="feet"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.feetId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="neck"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.neckId
                    )}
                  />
                </div>
                <div className="">
                  <ItemDisplay
                    type="ring"
                    item={items.find(
                      (item: any) => item.id == formatAdventurer.ringId
                    )}
                  />
                </div>
              </div>
              <div className="flex flex-col space-y-1 text-xl justify-between px-3 bg-terminal-green text-terminal-black">
                <div className="">STRENGTH {formatAdventurer.strength}</div>
                <div className="">DEXTERITY {formatAdventurer.dexterity}</div>
                <div className="">
                  INTELLIGENCE {formatAdventurer.intelligence}
                </div>
                <div className="">VITALITY {formatAdventurer.vitality}</div>
                <div className="">WISDOM {formatAdventurer.wisdom}</div>
                <div className="">LUCK {formatAdventurer.luck}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
