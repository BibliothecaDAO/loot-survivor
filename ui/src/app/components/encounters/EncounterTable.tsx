import {
  BladeIcon,
  BludgeonIcon,
  MagicIcon,
  ClothIcon,
  HideIcon,
  MetalIcon,
  HeartVitalityIcon,
  CoinIcon,
} from "@/app/components/icons/Icons";
import React, { useEffect, useMemo, useState } from "react";
import {
  listAllEncounters,
  beastEncounters,
} from "@/app/lib/utils/processFutures";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { getItemData, calculateLevel } from "@/app/lib/utils";
import useUIStore from "@/app/hooks/useUIStore";
import { MdClose } from "react-icons/md";
import { Button } from "@/app/components/buttons/Button";

const EncounterTable = () => {
  const [view, setView] = useState<number>(0);

  const [beastTable, setBeastTable] = useState<any>([]);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const adventurerEntropy = useUIStore((state) => state.adventurerEntropy);
  const showEncounterTable = useUIStore((state) => state.showEncounterTable);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);

  const formattedAdventurerEntropy = BigInt(adventurerEntropy);

  const { data } = useQueriesStore();

  let armoritems =
    data.itemsByAdventurerQuery?.items
      .map((item) => ({ ...item, ...getItemData(item.item ?? "") }))
      .filter((item) => {
        return !["Weapon", "Ring", "Neck"].includes(item.slot!);
      }) || [];

  let weaponItems =
    data.itemsByAdventurerQuery?.items
      .map((item) => ({ ...item, ...getItemData(item.item ?? "") }))
      .filter((item) => {
        return item.slot! === "Weapon";
      }) || [];

  const encounters = useMemo(
    () =>
      listAllEncounters(
        adventurer?.xp!,
        formattedAdventurerEntropy,
        hasBeast,
        adventurer?.level!
      ),
    [adventurer?.xp, formattedAdventurerEntropy]
  );

  useEffect(() => {
    if (view === 1) {
      setBeastTable(
        beastEncounters(
          encounters.map((encounter: any) => encounter.xp),
          formattedAdventurerEntropy
        )
      );
    }
  }, [encounters, formattedAdventurerEntropy, view]);

  return (
    <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row justify-between w-full bg-terminal-black max-h-[300px] border border-terminal-green text-xs sm:text-base">
      <div className="flex flex-col w-full flex-grow-2">
        <div className="flex w-full justify-center h-8">
          <Button
            variant={view === 0 ? "default" : "outline"}
            onClick={() => setView(0)}
          >
            All
          </Button>
          <Button
            variant={view === 1 ? "default" : "outline"}
            onClick={() => setView(1)}
          >
            Beast
          </Button>
        </div>
        <button
          className="absolute top-0 right-0"
          onClick={() => showEncounterTable(false)}
        >
          <MdClose className="w-10 h-10" />
        </button>

        <table className="border-separate border-spacing-0 w-full sm:text-sm xl:text-sm 2xl:text-sm block overflow-x-scroll sm:overflow-y-scroll default-scroll p-2">
          <thead
            className="border border-terminal-green sticky top-0 bg-terminal-black uppercase"
            style={{ zIndex: 8 }}
          >
            <tr className="border border-terminal-green">
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                XP (lvl)
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Encounter
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Tier
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Lvl
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                HP
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Type
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Location
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Avoid
              </th>
              <th className="py-2 px-1 sm:pr-3 border-b border-terminal-green">
                Crit
              </th>
              <th className="py-2 px-1 border-b border-terminal-green">
                Next XP (Lvl)
              </th>
            </tr>
          </thead>
          {view === 0 && (
            <tbody>
              {adventurerEntropy ? (
                React.Children.toArray(
                  encounters.map((encounter: any) => {
                    let [special2, special3] = encounter.specialName?.split(
                      " "
                    ) || ["no", "no"];
                    let nameMatch =
                      encounter.encounter === "Beast" && encounter.level >= 19
                        ? armoritems.find(
                            (item) =>
                              item.special2 === special2 ||
                              item.special3 === special3
                          )
                        : false;
                    let weaponMatch =
                      encounter.encounter === "Beast" && encounter.level >= 19
                        ? weaponItems.find(
                            (item) =>
                              item.special2 === special2 ||
                              item.special3 === special3
                          )
                        : false;

                    return (
                      <tr className="">
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex">
                            {encounter.xp}. ({encounter.adventurerLevel})
                          </span>
                        </td>
                        <td
                          className={`py-2 border-b border-terminal-green tooltip ${
                            nameMatch
                              ? "text-red-500"
                              : weaponMatch
                              ? "text-green-500"
                              : "text-terminal-yellow"
                          }`}
                        >
                          <span className="uppercase">
                            {encounter.encounter}
                          </span>
                          {encounter.encounter === "Beast" &&
                            encounter.level >= 19 && (
                              <span className="tooltiptext bottom">
                                {encounter.specialName}
                              </span>
                            )}
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.encounter !== "Discovery" &&
                              encounter.tier}
                            {encounter.type === "Health" && (
                              <div className="flex items-center">
                                {" "}
                                {encounter.tier}{" "}
                                <HeartVitalityIcon className="h-3 pl-0.5" />
                              </div>
                            )}
                            {encounter.type === "Gold" && (
                              <div className="flex items-center">
                                {" "}
                                {encounter.tier}{" "}
                                <CoinIcon className="pl-0.5 mt-0.5 self-center h-4 fill-current text-terminal-yellow" />
                              </div>
                            )}
                          </span>
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.level}
                          </span>
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.health}
                          </span>
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center gap-1 items-center">
                            {encounter.type === "Blade" && (
                              <BladeIcon className="h-4" />
                            )}
                            {encounter.type === "Bludgeon" && (
                              <BludgeonIcon className="h-4" />
                            )}
                            {encounter.type === "Magic" && (
                              <MagicIcon className="h-4" />
                            )}

                            {encounter.encounter === "Beast" && (
                              <>
                                <span>/</span>
                                {encounter.type === "Blade" && (
                                  <HideIcon className="h-4" />
                                )}
                                {encounter.type === "Bludgeon" && (
                                  <MetalIcon className="h-4" />
                                )}
                                {encounter.type === "Magic" && (
                                  <ClothIcon className="h-4" />
                                )}
                              </>
                            )}
                          </span>
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.location}
                          </span>
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex items-center gap-1">
                            <span className="uppercase">
                              {encounter.dodgeRoll &&
                                ((encounter.encounter === "Beast"
                                  ? adventurer?.wisdom!
                                  : adventurer?.intelligence!) >
                                encounter.dodgeRoll
                                  ? "Yes"
                                  : "No")}
                            </span>
                            <span className="flex justify-center">
                              {encounter.dodgeRoll &&
                                `(${encounter.dodgeRoll})`}
                            </span>
                          </span>
                        </td>
                        <td
                          className={`py-2 border-b border-terminal-green ${
                            encounter.criticalMultiplier > 3
                              ? "text-red-500"
                              : encounter.criticalMultiplier > 0
                              ? "text-terminal-yellow"
                              : ""
                          }`}
                        >
                          {encounter.criticalMultiplier >= 0 && (
                            <span className="flex justify-center">
                              {encounter.criticalMultiplier > 0
                                ? `${encounter.criticalMultiplier * 20}%`
                                : "No"}
                            </span>
                          )}
                        </td>
                        <td className="py-2 border-b border-terminal-green">
                          <span className="flex justify-center text-terminal-yellow">
                            {encounter.nextXp} (
                            {calculateLevel(encounter.nextXp)})
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )
              ) : (
                <tr className="flex items-center h-10 absolute">
                  <span className="p-4">
                    Waiting for new entropy... somebody has to rotate it!
                  </span>
                </tr>
              )}
            </tbody>
          )}

          {view === 1 && (
            <tbody>
              {adventurerEntropy ? (
                React.Children.toArray(
                  beastTable.map((encounter: any) => {
                    let [special2, special3] = encounter.specialName?.split(
                      " "
                    ) || ["no", "no"];
                    let nameMatch =
                      encounter.encounter === "Beast" && encounter.level >= 19
                        ? armoritems.find(
                            (item) =>
                              item.special2 === special2 ||
                              item.special3 === special3
                          )
                        : false;
                    let weaponMatch =
                      encounter.encounter === "Beast" && encounter.level >= 19
                        ? weaponItems.find(
                            (item) =>
                              item.special2 === special2 ||
                              item.special3 === special3
                          )
                        : false;

                    return (
                      <tr className="">
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex">
                            {encounter.xp}. ({encounter.adventurerLevel})
                          </span>
                        </td>
                        <td
                          className={`p-2 border-b border-terminal-green tooltip ${
                            nameMatch
                              ? "text-red-500"
                              : weaponMatch
                              ? "text-green-500"
                              : "text-terminal-yellow"
                          }`}
                        >
                          {encounter.encounter}
                          {encounter.encounter === "Beast" &&
                            encounter.level >= 19 && (
                              <span className="tooltiptext bottom">
                                {encounter.specialName}
                              </span>
                            )}
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.encounter !== "Discovery" &&
                              encounter.tier}
                            {encounter.type === "Health" && (
                              <div className="flex items-center">
                                {" "}
                                {encounter.tier}{" "}
                                <HeartVitalityIcon className="h-3 pl-0.5" />
                              </div>
                            )}
                            {encounter.type === "Gold" && (
                              <div className="flex items-center">
                                {" "}
                                {encounter.tier}{" "}
                                <CoinIcon className="pl-0.5 mt-0.5 self-center h-4 fill-current text-terminal-yellow" />
                              </div>
                            )}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.level}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.health}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center gap-1 items-center">
                            {encounter.type === "Blade" && (
                              <BladeIcon className="h-4" />
                            )}
                            {encounter.type === "Bludgeon" && (
                              <BludgeonIcon className="h-4" />
                            )}
                            {encounter.type === "Magic" && (
                              <MagicIcon className="h-4" />
                            )}

                            {encounter.encounter === "Beast" && (
                              <>
                                <span>/</span>
                                {encounter.type === "Blade" && (
                                  <HideIcon className="h-4" />
                                )}
                                {encounter.type === "Bludgeon" && (
                                  <MetalIcon className="h-4" />
                                )}
                                {encounter.type === "Magic" && (
                                  <ClothIcon className="h-4" />
                                )}
                              </>
                            )}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.location}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center">
                            {encounter.dodgeRoll}
                          </span>
                        </td>
                        <td className="p-2 border-b border-terminal-green"></td>
                        <td className="p-2 border-b border-terminal-green">
                          <span className="flex justify-center text-terminal-yellow">
                            {encounter.nextXp} (
                            {calculateLevel(encounter.nextXp)})
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )
              ) : (
                <tr className="flex items-center h-10 absolute">
                  <span className="p-4">
                    Waiting for randomness from Pragma!
                  </span>
                </tr>
              )}
            </tbody>
          )}
        </table>
      </div>
    </div>
  );
};

export default EncounterTable;
