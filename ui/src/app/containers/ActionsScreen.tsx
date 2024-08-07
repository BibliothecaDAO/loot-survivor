import { useEffect, useState } from "react";
import { Contract } from "starknet";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import Info from "@/app/components/adventurer/Info";
import Discovery from "@/app/components/actions/Discovery";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import BeastScreen from "@/app/containers/BeastScreen";
import MazeLoader from "@/app/components/icons/MazeLoader";
import useUIStore from "@/app/hooks/useUIStore";
import ActionMenu from "@/app/components/menu/ActionMenu";
import { Beast } from "@/app/types";
import { useController } from "@/app/context/ControllerContext";
import { getItemData } from "@/app/lib/utils";
import { getNextBigEncounter } from "@/app/lib/utils/processFutures";
import {
  BladeIcon,
  BludgeonIcon,
  MagicIcon,
  ClothIcon,
  HideIcon,
  MetalIcon,
} from "@/app/components/icons/Icons";
import LootIcon from "@/app/components/icons/LootIcon";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { GameData } from "../lib/data/GameData";
import { Button } from "../components/buttons/Button";
import { useMemo } from "react";

interface ActionsScreenProps {
  explore: (till_beast: boolean) => Promise<void>;
  attack: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  flee: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  gameContract: Contract;
  beastsContract: Contract;
}

/**
 * @container
 * @description Provides the actions screen for the adventurer.
 */
export default function ActionsScreen({
  explore,
  attack,
  flee,
  gameContract,
  beastsContract,
}: ActionsScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);
  const onKatana = useUIStore((state) => state.onKatana);

  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const latestDiscoveries = useQueriesStore((state) =>
    state.data.latestDiscoveriesQuery
      ? state.data.latestDiscoveriesQuery.discoveries
      : []
  );

  const adventurerEntropy = useUIStore((state) => state.adventurerEntropy);

  const [nextEncounter, setNextEncounter] = useState<any>();
  const [showFuture, setShowFuture] = useState(false);

  const { data } = useQueriesStore();

  const items = useMemo(() => {
    return data.itemsByAdventurerQuery?.items
      .filter((item) => item.equipped)
      .map((item) => ({
        item: item.item,
        ...getItemData(item.item ?? ""),
        special2: item.special2,
        special3: item.special3,
        xp: Math.max(1, item.xp!),
      }));
  }, [data.itemsByAdventurerQuery?.items]);

  useEffect(() => {
    if (!adventurer?.xp || !adventurerEntropy) {
      return;
    }

    setNextEncounter(
      getNextBigEncounter(
        adventurer?.level!,
        adventurer?.xp,
        adventurerEntropy,
        items!
      )
    );
  }, [adventurer?.id, adventurer?.xp, items]);

  const gameData = new GameData();

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const handleSingleExplore = async () => {
    resetNotification();
    await explore(false);
  };

  const handleExploreTillBeast = async () => {
    resetNotification();
    await explore(true);
  };

  const { addControl } = useController();

  useEffect(() => {
    addControl("e", () => {
      console.log("Key e pressed");
      handleSingleExplore();
      clickPlay();
    });
    addControl("r", () => {
      console.log("Key r pressed");
      handleExploreTillBeast();
      clickPlay();
    });
  }, []);

  const buttonsData = [
    {
      id: 1,
      label: loading ? "Exploring..." : hasBeast ? "Beast found!!" : "Once",
      value: "explore",
      action: async () => {
        handleSingleExplore();
      },
      disabled: hasBeast || loading || !adventurer?.id || estimatingFee,
      loading: loading,
      className:
        "bg-terminal-green-25 hover:bg-terminal-green hover:text-black",
    },
    {
      id: 2,
      label: loading
        ? "Exploring..."
        : hasBeast
        ? "Beast found!!"
        : "Till Beast",
      value: "explore",
      action: async () => {
        handleExploreTillBeast();
      },
      disabled: hasBeast || loading || !adventurer?.id || estimatingFee,
      loading: loading,
      className:
        "bg-terminal-green-50 hover:bg-terminal-green hover:text-black",
    },
  ];

  return (
    <div className="flex flex-col sm:flex-row flex-wrap h-full w-full">
      <div className="hidden sm:block sm:w-1/2 lg:w-1/3 h-full">
        <Info adventurer={adventurer} gameContract={gameContract} />
      </div>

      {hasBeast ? (
        <BeastScreen
          attack={attack}
          flee={flee}
          beastsContract={beastsContract}
        />
      ) : (
        <div className="flex flex-col sm:flex-row h-full w-full sm:w-1/2 lg:w-2/3">
          {adventurer?.id ? (
            <div className="flex flex-col items-center lg:w-1/2 bg-terminal-black order-1 sm:order-2 h-5/6 sm:h-full">
              {!showFuture ? (
                <Discovery discoveries={latestDiscoveries} />
              ) : null}
              <Button
                className="uppercase sm:hidden"
                onClick={() => setShowFuture(!showFuture)}
              >
                {showFuture ? "Hide Future" : "Show Future"}
              </Button>
              {nextEncounter && showFuture && (
                <div className="sm:hidden flex-col items-center uppercase mt-8">
                  <div className="text-center">Next Big Encounter</div>

                  <div className="text-sm border p-2 border-terminal-green flex flex-col items-center mt-2 gap-1 w-[220px]">
                    {nextEncounter?.encounter! === "levelup" && (
                      <span className="text-base">Level Up!</span>
                    )}

                    {nextEncounter?.encounter! === "Beast" && (
                      <>
                        <div className="flex flex-col items-center gap-2 mb-1">
                          <span className="text-terminal-yellow text-center">
                            Beast{" "}
                            {nextEncounter.level >= 19
                              ? `"${nextEncounter.specialName}"`
                              : ""}
                          </span>

                          <span className="text-center">
                            {gameData.BEASTS[nextEncounter.id]}
                          </span>

                          <span className="flex gap-4">
                            <span>Tier {nextEncounter.tier}</span>
                            <span>Level {nextEncounter.level}</span>
                          </span>

                          <span className="flex justify-center gap-2 items-center">
                            {nextEncounter.type === "Blade" && (
                              <BladeIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Bludgeon" && (
                              <BludgeonIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Magic" && (
                              <MagicIcon className="h-4" />
                            )}
                            <span>{nextEncounter.type}</span>
                            <span>/</span>
                            {nextEncounter.type === "Blade" && (
                              <HideIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Bludgeon" && (
                              <MetalIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Magic" && (
                              <ClothIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Blade"
                              ? "Hide"
                              : nextEncounter.type === "Bludgeon"
                              ? "Metal"
                              : "Cloth"}
                          </span>
                          {nextEncounter?.encounter === "Beast" &&
                          nextEncounter.dodgeRoll <= adventurer?.wisdom! ? (
                            <div className="text-sm">No Ambush</div>
                          ) : (
                            <div className="text-sm flex flex-col items-center">
                              <span>Ambush!</span>
                              <div className="flex gap-1 items-center">
                                <span>
                                  Damage to {nextEncounter.location} for{" "}
                                  {nextEncounter.damage}
                                </span>
                                <span className="text-red-500">
                                  <LootIcon
                                    size={"w-4"}
                                    type={nextEncounter.location}
                                  />
                                </span>
                              </div>
                            </div>
                          )}
                        </div>
                      </>
                    )}

                    {nextEncounter?.encounter! === "Obstacle" && (
                      <>
                        <div className="flex flex-col items-center gap-1">
                          <span className="text-base text-terminal-yellow">
                            Obstacle
                          </span>

                          <span className="text-base text-terminal-green">
                            {gameData.OBSTACLES[parseInt(nextEncounter.id)]}
                          </span>

                          <span className="flex gap-4">
                            <span>Tier {nextEncounter.tier}</span>
                            <span>Level {nextEncounter.level}</span>
                          </span>
                          <span className="flex justify-center gap-2 items-center">
                            {nextEncounter.type === "Blade" && (
                              <BladeIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Bludgeon" && (
                              <BludgeonIcon className="h-4" />
                            )}
                            {nextEncounter.type === "Magic" && (
                              <MagicIcon className="h-4" />
                            )}
                            {nextEncounter.type}
                          </span>
                          {nextEncounter.dodgeRoll <=
                          adventurer?.intelligence! ? (
                            <div className="text-sm">Avoided</div>
                          ) : (
                            <div className="text-sm flex flex-col items-center gap-1">
                              <div className="flex gap-1 items-center">
                                <span>
                                  Damage to {nextEncounter.location} for{" "}
                                  {nextEncounter.damage}
                                </span>
                                <span className="text-red-500">
                                  <LootIcon
                                    size={"w-4"}
                                    type={nextEncounter.location}
                                  />
                                </span>
                              </div>
                            </div>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                </div>
              )}
            </div>
          ) : (
            <p className="text-xl text-center order-1 sm:order-2">
              Please Select an Adventurer
            </p>
          )}
          <div className="flex flex-col items-center lg:w-1/2 my-4 w-full px-4 sm:order-1 h-1/6 sm:h-full">
            {loading && !onKatana && <MazeLoader />}
            <div className="w-3/4 h-full sm:h-1/6">
              <ActionMenu
                buttonsData={buttonsData}
                size="fill"
                title="Explore"
              />
            </div>

            {nextEncounter && (
              <div className="hidden sm:flex flex-col items-center uppercase mt-8">
                <div>Next Big Encounter</div>

                <div className="text-sm border p-2 border-terminal-green flex flex-col items-center mt-2 gap-1 w-[220px]">
                  {nextEncounter?.encounter! === "levelup" && (
                    <span className="text-base">Level Up!</span>
                  )}

                  {nextEncounter?.encounter! === "Beast" && (
                    <>
                      <div className="flex flex-col items-center gap-2 mb-1">
                        <span className="text-terminal-yellow text-center">
                          Beast{" "}
                          {nextEncounter.level >= 19
                            ? `"${nextEncounter.specialName}"`
                            : ""}
                        </span>

                        <span className="text-center">
                          {gameData.BEASTS[nextEncounter.id]}
                        </span>

                        <span className="flex gap-4">
                          <span>Tier {nextEncounter.tier}</span>
                          <span>Level {nextEncounter.level}</span>
                        </span>

                        <span className="flex justify-center gap-2 items-center">
                          {nextEncounter.type === "Blade" && (
                            <BladeIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Bludgeon" && (
                            <BludgeonIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Magic" && (
                            <MagicIcon className="h-4" />
                          )}
                          <span>{nextEncounter.type}</span>
                          <span>/</span>
                          {nextEncounter.type === "Blade" && (
                            <HideIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Bludgeon" && (
                            <MetalIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Magic" && (
                            <ClothIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Blade"
                            ? "Hide"
                            : nextEncounter.type === "Bludgeon"
                            ? "Metal"
                            : "Cloth"}
                        </span>
                        {nextEncounter?.encounter === "Beast" &&
                        nextEncounter.dodgeRoll <= adventurer?.wisdom! ? (
                          <div className="text-sm">No Ambush</div>
                        ) : (
                          <div className="text-sm flex flex-col items-center">
                            <span>Ambush!</span>
                            <div className="flex gap-1 items-center">
                              <span>
                                Damage to {nextEncounter.location} for{" "}
                                {nextEncounter.damage}
                              </span>
                              <span className="text-red-500">
                                <LootIcon
                                  size={"w-4"}
                                  type={nextEncounter.location}
                                />
                              </span>
                            </div>
                          </div>
                        )}
                      </div>
                    </>
                  )}

                  {nextEncounter?.encounter! === "Obstacle" && (
                    <>
                      <div className="flex flex-col items-center gap-1">
                        <span className="text-base text-terminal-yellow">
                          Obstacle
                        </span>

                        <span className="text-base text-terminal-green">
                          {gameData.OBSTACLES[parseInt(nextEncounter.id)]}
                        </span>

                        <span className="flex gap-4">
                          <span>Tier {nextEncounter.tier}</span>
                          <span>Level {nextEncounter.level}</span>
                        </span>
                        <span className="flex justify-center gap-2 items-center">
                          {nextEncounter.type === "Blade" && (
                            <BladeIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Bludgeon" && (
                            <BludgeonIcon className="h-4" />
                          )}
                          {nextEncounter.type === "Magic" && (
                            <MagicIcon className="h-4" />
                          )}
                          {nextEncounter.type}
                        </span>
                        {nextEncounter.dodgeRoll <=
                        adventurer?.intelligence! ? (
                          <div className="text-sm">Avoided</div>
                        ) : (
                          <div className="text-sm flex flex-col items-center gap-1">
                            <div className="flex gap-1 items-center">
                              <span>
                                Damage to {nextEncounter.location} for{" "}
                                {nextEncounter.damage}
                              </span>
                              <span className="text-red-500">
                                <LootIcon
                                  size={"w-4"}
                                  type={nextEncounter.location}
                                />
                              </span>
                            </div>
                          </div>
                        )}
                      </div>
                    </>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
