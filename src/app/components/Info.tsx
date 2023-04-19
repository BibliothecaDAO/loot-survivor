import { useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import Image from "next/image";
import VerticalKeyboardControl from "./VerticalMenu";

export default function Info() {
  const [loading, setLoading] = useState(false);

  const { adventurer, handleUpdateAdventurer } = useAdventurer();

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

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
              <div className="flex flex-col items-center mt-9">
                <div className="text-xl font-medium text-white">
                  {formatAdventurer.adventurer?.name}
                </div>
                <p className="text-lg text-terminal-green">
                  HEALTH {formatAdventurer.adventurer?.health}
                </p>
                <p className="text-lg text-terminal-yellow">
                  GOLD {formatAdventurer.adventurer?.gold}
                </p>
                <p className="text-lg text-red-600">
                  BEAST {formatAdventurer.adventurer?.beast}
                </p>
                <p className="text-lg text-terminal-green">
                  XP {formatAdventurer.adventurer?.xp}
                </p>
              </div>
            </div>
          </div>
          <div className="flex flex-row justify-evenly mt-4">
            <div className="flex flex-col m-2">
              <div className="text-xl font-medium text-white">ITEMS</div>
              <p className="text-terminal-green">
                WEAPON - {formatAdventurer.adventurer?.weaponId}
              </p>
              <p className="text-terminal-green">
                HEAD - {formatAdventurer.adventurer?.headId}
              </p>
              <p className="text-terminal-green">
                CHEST - {formatAdventurer.adventurer?.chestId}
              </p>
              <p className="text-terminal-green">
                FOOT - {formatAdventurer.adventurer?.feetId}
              </p>
              <p className="text-terminal-green">
                HAND - {formatAdventurer.adventurer?.handsId}
              </p>
              <p className="text-terminal-green">
                WAIST - {formatAdventurer.adventurer?.waistId}
              </p>
            </div>
            <div className="flex flex-col m-2">
              <div className="text-xl font-medium text-white">STATISTICS</div>
              <p className="text-terminal-green">
                STRENGTH - {formatAdventurer.adventurer?.strength}
              </p>
              <p className="text-terminal-green">
                DEXTERITY - {formatAdventurer.adventurer?.dexterity}
              </p>
              <p className="text-terminal-green">
                INTELLIGENCE - {formatAdventurer.adventurer?.intelligence}
              </p>
              <p className="text-terminal-green">
                VITALITY - {formatAdventurer.adventurer?.vitality}
              </p>
              <p className="text-terminal-green">
                WISDOM - {formatAdventurer.adventurer?.wisdom}
              </p>
              <p className="text-terminal-green">
                LUCK - {formatAdventurer.adventurer?.luck}
              </p>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
