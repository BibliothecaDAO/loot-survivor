import { useState } from "react";
import { NullAdventurer } from "../types";
import Image from "next/image";
import { useQuery } from "@apollo/client";
import { getItemsByAdventurer } from "../hooks/graphql/queries";
interface InfoProps {
  adventurer: any;
}

export default function Info({ adventurer }: InfoProps) {
  const [loading, setLoading] = useState(false);

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

  const ItemDisplay = (item: any) => {
    const formatItem = item.item;
    return <>{formatItem ? formatItem.item : "Nothing"}</>;
  };

  return (
    <div className="h-full p-2 bg-terminal-black">
      {!loading ? (
        <>
          <div className="flex flex-row justify-evenly">
            <div className="flex flex-row gap-5 m-4">
              <div className="w-[170px] h-[160px] relative border-4 border-white ">
                <Image
                  src={
                    formatAdventurer.health == 0 ? "/skull.png" : "/MIKE.png"
                  }
                  alt="adventurer-image"
                  fill={true}
                  style={{ objectFit: "contain" }}
                />
              </div>
              <div className="flex flex-col items-center ml-2 mt-9">
                <div className="text-2xl font-medium text-white">
                  {formatAdventurer.name}
                </div>
                <p className="text-2xl text-terminal-green">
                  HEALTH {formatAdventurer.health}
                </p>
                <p className="text-2xl text-terminal-yellow">
                  GOLD {formatAdventurer.gold}
                </p>
                <p className="text-2xl text-white">
                  LEVEL {formatAdventurer.level}
                </p>
                <p className="text-2xl text-terminal-green">
                  XP {formatAdventurer.xp}
                </p>
              </div>
            </div>
          </div>
          <div className="flex flex-row mt-4 justify-evenly">
            <div className="flex flex-col">
              <div className="text-2xl font-medium text-white">ITEMS</div>
              <p className="text-xl text-terminal-green">
                WEAPON -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.weaponId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                HEAD -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.headId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                CHEST -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.chestId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                HAND -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.handsId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                WAIST -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.waistId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                FOOT -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.feetId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                NECK -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.neckId
                  )}
                />
              </p>
              <p className="text-terminal-green text-l">
                RING -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.ringId
                  )}
                />
              </p>
            </div>
            <div className="flex flex-col">
              <div className="text-2xl font-medium text-white">STATISTICS</div>
              <p className="text-xl text-terminal-green">
                STRENGTH - {formatAdventurer.strength}
              </p>
              <p className="text-xl text-terminal-green">
                DEXTERITY - {formatAdventurer.dexterity}
              </p>
              <p className="text-xl text-terminal-green">
                INTELLIGENCE - {formatAdventurer.intelligence}
              </p>
              <p className="text-xl text-terminal-green">
                VITALITY - {formatAdventurer.vitality}
              </p>
              <p className="text-xl text-terminal-green">
                WISDOM - {formatAdventurer.wisdom}
              </p>
              <p className="text-xl text-terminal-green">
                LUCK - {formatAdventurer.luck}
              </p>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
