import React, { useState, useEffect } from "react";
import KeyboardControl, { ButtonData } from "../components/KeyboardControls";
import { BattleDisplay } from "../components/beast/BattleDisplay";
import { BeastDisplay } from "../components/beast/BeastDisplay";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { useQueriesStore } from "../hooks/useQueryStore";
import { processBeastName } from "../lib/utils";
import { Battle, NullBeast } from "../types";
import { Button } from "../components/buttons/Button";
import useUIStore from "../hooks/useUIStore";
import InterludeScreen from "./InterludeScreen";
import { getBlock } from "../api/api";
import { useBlock } from "@starknet-react/core";

interface BeastScreenProps {
  attack: (...args: any[]) => any;
  flee: (...args: any[]) => any;
}

/**
 * @container
 * @description Provides the beast screen for adventurer battles.
 */
export default function BeastScreen({ attack, flee }: BeastScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const [showBattleLog, setShowBattleLog] = useState(false);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);
  const setData = useQueriesStore((state) => state.setData);
  const beastData = useQueriesStore(
    (state) => state.data.beastQuery?.beasts[0] || NullBeast
  );
  const formatBattles = useQueriesStore(
    (state) => state.data.battlesByBeastQuery?.battles || []
  );

  const { data: blockData } = useBlock({
    refetchInterval: false,
  });

  const [buttonText, setButtonText] = useState("Flee");

  const handleMouseEnter = () => {
    setButtonText("You Coward!");
  };

  const handleMouseLeave = () => {
    setButtonText("Flee");
  };

  const attackButtonsData: ButtonData[] = [
    {
      id: 1,
      label: "SINGLE",
      action: async () => {
        resetNotification();
        await attack(false, beastData);
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        estimatingFee,
      loading: loading,
    },
    {
      id: 2,
      label: "TILL DEATH",
      action: async () => {
        resetNotification();
        await attack(true, beastData);
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        estimatingFee,
      loading: loading,
    },
  ];

  const fleeButtonsData: ButtonData[] = [
    {
      id: 1,
      label: adventurer?.dexterity === 0 ? "DEX TOO LOW" : "SINGLE",
      mouseEnter: handleMouseEnter,
      mouseLeave: handleMouseLeave,
      action: async () => {
        resetNotification();
        await flee(false, beastData);
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        adventurer?.level == 1 ||
        adventurer.dexterity === 0 ||
        estimatingFee,
      loading: loading,
    },
    {
      id: 2,
      label: adventurer?.dexterity === 0 ? "DEX TOO LOW" : "TILL DEATH",
      mouseEnter: handleMouseEnter,
      mouseLeave: handleMouseLeave,
      action: async () => {
        resetNotification();
        await flee(true, beastData);
      },
      disabled:
        adventurer?.beastHealth == undefined ||
        adventurer?.beastHealth == 0 ||
        loading ||
        adventurer?.level == 1 ||
        adventurer.dexterity === 0 ||
        estimatingFee,
      loading: loading,
    },
  ];

  const beastName = processBeastName(
    beastData?.beast ?? "",
    beastData?.special2 ?? "",
    beastData?.special3 ?? ""
  );

  const BattleLog: React.FC = () => (
    <div className="flex flex-col p-2 items-center">
      <Button
        className="w-1/2 sm:hidden"
        onClick={() => setShowBattleLog(false)}
      >
        Back
      </Button>
      <div className="flex flex-col items-center gap-5 p-2">
        <div className="text-xl uppercase">
          Battle log with {beastData?.beast}
        </div>
        <div className="flex flex-col gap-2 ext-sm overflow-y-auto h-96 text-center">
          {formatBattles.map((battle: Battle, index: number) => (
            <div className="border p-2 border-terminal-green" key={index}>
              <BattleDisplay battleData={battle} beastName={beastName} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  if (showBattleLog) {
    return <BattleLog />;
  }

  console.log(blockData?.block_number, adventurer?.revealBlock);

  return (
    <div className="sm:w-2/3 flex flex-col sm:flex-row h-full">
      {(blockData?.block_number ?? 1) < (adventurer?.revealBlock ?? 0) && (
        <InterludeScreen />
      )}
      <div className="sm:w-1/2 order-1 sm:order-2">
        {hasBeast ? (
          <BeastDisplay beastData={beastData} />
        ) : (
          <div className="flex flex-col items-center border-2 border-terminal-green">
            <p className="m-auto text-lg uppercase text-terminal-green">
              Beast not yet discovered.
            </p>
          </div>
        )}
      </div>

      <div className="flex flex-col gap-1 sm:gap-0 items-center sm:w-1/2 sm:p-4 order-1 text-lg">
        {isAlive && (
          <>
            <div className="sm:hidden flex flex-row sm:flex-col items-center w-full">
              <div className="flex flex-col items-center border border-terminal-green w-full">
                <p className="uppercase sm:text-2xl mb-2">Attack</p>
                <KeyboardControl
                  buttonsData={attackButtonsData}
                  size={"sm"}
                  direction="row"
                />
              </div>
              <div className="flex flex-col items-center border border-terminal-green w-full">
                <p className="uppercase sm:text-2xl mb-2">Flee</p>
                <KeyboardControl
                  buttonsData={fleeButtonsData}
                  size={"sm"}
                  direction="row"
                />
              </div>
            </div>
            <div className="hidden sm:block flex flex-row gap-2 sm:flex-col items-center justify-center">
              <div className="flex flex-col items-center justify-center">
                <p className="uppercase sm:text-xl 2xl:text-2xl">Attack</p>
                <KeyboardControl
                  buttonsData={attackButtonsData}
                  size={"xl"}
                  direction="row"
                />
              </div>
              <div className="flex flex-col items-center">
                <p className="uppercase sm:text-xl 2xl:text-2xl">
                  {buttonText}
                </p>
                <KeyboardControl
                  buttonsData={fleeButtonsData}
                  size={"xl"}
                  direction="row"
                />
              </div>
            </div>
          </>
        )}

        <div className="hidden sm:block">
          {(hasBeast || formatBattles.length > 0) && <BattleLog />}
        </div>

        <Button
          className="sm:hidden uppercase"
          onClick={() => setShowBattleLog(true)}
        >
          Battle log with {beastData?.beast}
        </Button>
      </div>
    </div>
  );
}
