import { useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurer } from "../types";
import Image from "next/image";
import VerticalKeyboardControl from "./VerticalMenu";
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
    <div className="p-2 bg-terminal-black">
      {!loading ? (
        <>
          <div className="flex flex-row justify-evenly">
            <div className="flex flex-row m-4 gap-5">
              <div className="w-[160px] h-[160px] relative border-4 border-white ">
                <Image
                  src="/MIKE.png"
                  alt="adventurer-image"
                  fill={true}
                  style={{ objectFit: "contain" }}
                />
              </div>
              <div className="flex flex-col items-center mt-9 ml-2">
                <div className="text-xl font-medium text-white">
                  {formatAdventurer.name}
                </div>
                <p className="text-lg text-terminal-green">
                  HEALTH {formatAdventurer.health}
                </p>
                <p className="text-lg text-terminal-yellow">
                  GOLD {formatAdventurer.gold}
                </p>
                <p className="text-lg text-white">
                  LEVEL {formatAdventurer.level}
                </p>
                <p className="text-lg text-terminal-green">
                  XP {formatAdventurer.xp}
                </p>
              </div>
            </div>
          </div>
          <div className="flex flex-row justify-evenly mt-4">
            <div className="flex flex-col">
              <div className="text-xl font-medium text-white">ITEMS</div>
              <p className="text-terminal-green">
                WEAPON -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.weaponId
                  )}
                />
              </p>
              <p className="text-terminal-green">
                HEAD -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.headId
                  )}
                />
              </p>
              <p className="text-terminal-green">
                CHEST -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.chestId
                  )}
                />
              </p>
              <p className="text-terminal-green">
                FOOT -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.feetId
                  )}
                />
              </p>
              <p className="text-terminal-green">
                HAND -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.handsId
                  )}
                />
              </p>
              <p className="text-terminal-green">
                WAIST -{" "}
                <ItemDisplay
                  item={items.find(
                    (item: any) => item.id == formatAdventurer.waistId
                  )}
                />
              </p>
            </div>
            <div className="flex flex-col">
              <div className="text-xl font-medium text-white">STATISTICS</div>
              <p className="text-terminal-green">
                STRENGTH - {formatAdventurer.strength}
              </p>
              <p className="text-terminal-green">
                DEXTERITY - {formatAdventurer.dexterity}
              </p>
              <p className="text-terminal-green">
                INTELLIGENCE - {formatAdventurer.intelligence}
              </p>
              <p className="text-terminal-green">
                VITALITY - {formatAdventurer.vitality}
              </p>
              <p className="text-terminal-green">
                WISDOM - {formatAdventurer.wisdom}
              </p>
              <p className="text-terminal-green">
                LUCK - {formatAdventurer.luck}
              </p>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
