import React, { useEffect, useState } from "react";
import { useBlock } from "@starknet-react/core";
import { Contract } from "starknet";
import { BattleDisplay } from "@/app/components/beast/BattleDisplay";
import { BeastDisplay } from "@/app/components/beast/BeastDisplay";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { processBeastName } from "@/app/lib/utils";
import { Battle, NullBeast, ButtonData, Beast } from "@/app/types";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import InterludeScreen from "@/app/containers/InterludeScreen";
import ActionMenu from "@/app/components/menu/ActionMenu";

interface BeastScreenProps {
  attack: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  flee: (tillDeath: boolean, beastData: Beast) => Promise<void>;
  beastsContract: Contract;
}

/**
 * @container
 * @description Provides the beast screen for adventurer battles.
 */
export default function BeastScreen({
  attack,
  flee,
  beastsContract,
}: BeastScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);
  const averageBlockTime = useUIStore((state) => state.averageBlockTime);
  const setUpdateDeathPenalty = useUIStore(
    (state) => state.setUpdateDeathPenalty
  );
  const setStartPenalty = useUIStore((state) => state.setStartPenalty);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const [showBattleLog, setShowBattleLog] = useState(false);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);
  const beastData = useQueriesStore(
    (state) => state.data.beastQuery?.beasts[0] || NullBeast
  );
  const formatBattles = useQueriesStore(
    (state) => state.data.battlesByBeastQuery?.battles || []
  );

  const mainnetBotProtection = process.env.NEXT_PUBLIC_NETWORK === "mainnet";

  const { data: blockData } = useBlock({
    refetchInterval:
      adventurer?.level === 1 && mainnetBotProtection ? 30000 : false,
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
      label: "ONCE",
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
      className:
        "bg-terminal-green-25 hover:bg-terminal-green hover:text-black justify-start sm:justify-center px-2 sm:px-0",
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
      className:
        "bg-terminal-green-50 hover:bg-terminal-green hover:text-black justify-end sm:justify-center px-2 sm:px-0",
    },
  ];

  const fleeButtonsData: ButtonData[] = [
    {
      id: 1,
      label: adventurer?.dexterity === 0 ? "DEX TOO LOW" : "ONCE",
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
      className:
        "bg-terminal-green-25 hover:bg-terminal-green hover:text-black justify-start sm:justify-center px-2 sm:px-0",
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
      className:
        "bg-terminal-green-50 hover:bg-terminal-green hover:text-black justify-end sm:justify-center px-2 sm:px-0",
    },
  ];

  const beastName = processBeastName(
    beastData?.beast ?? "",
    beastData?.special2 ?? "",
    beastData?.special3 ?? ""
  );

  const BattleLog: React.FC = () => (
    <div className="flex flex-col p-2 items-center h-full">
      <Button
        className="w-1/2 sm:hidden"
        onClick={() => setShowBattleLog(false)}
      >
        Back
      </Button>
      <div className="flex flex-col items-center gap-5 h-full">
        <div className="text-xl uppercase">
          Battle log with {beastData?.beast}
        </div>
        <div className="flex flex-col gap-2 ext-sm overflow-y-auto default-scroll h-full text-center">
          {formatBattles.map((battle: Battle, index: number) => (
            <div className="border p-2 border-terminal-green" key={index}>
              <BattleDisplay battleData={battle} beastName={beastName} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const currentBlockNumber = blockData?.block_number ?? 0;

  const revealBlockReached =
    currentBlockNumber >= (adventurer?.revealBlock ?? 0);

  useEffect(() => {
    if (revealBlockReached) {
      setStartPenalty(true);
      setUpdateDeathPenalty(true);
    }
  }, [currentBlockNumber]);

  if (showBattleLog) {
    return <BattleLog />;
  }

  return (
    <div className="sm:w-2/3 flex flex-col sm:flex-row h-full">
      {!revealBlockReached && mainnetBotProtection && (
        <InterludeScreen
          currentBlockNumber={currentBlockNumber}
          averageBlockTime={averageBlockTime}
        />
      )}
      <div className="sm:w-1/2 order-1 sm:order-2 h-3/4 sm:h-full">
        {hasBeast ? (
          <BeastDisplay beastData={beastData} beastsContract={beastsContract} />
        ) : (
          <div className="flex flex-col items-center border-2 border-terminal-green">
            <p className="m-auto text-lg uppercase text-terminal-green">
              Beast not yet discovered.
            </p>
          </div>
        )}
      </div>

      <div className="flex flex-col gap-1 sm:gap-5 items-center sm:w-1/2 order-1 text-lg h-1/4 sm:h-full">
        {isAlive && (
          <>
            {revealBlockReached || !mainnetBotProtection ? (
              <>
                <div className="sm:hidden flex flex-row sm:flex-col gap-5 items-center justify-center sm:justify-start w-full h-3/4 sm:h-1/4">
                  <div className="flex flex-col items-center w-1/2 sm:w-full h-1/2 sm:h-full">
                    <ActionMenu
                      buttonsData={attackButtonsData}
                      size={"fill"}
                      title="Attack"
                    />
                  </div>
                  <div className="flex flex-col items-center w-1/2 sm:w-full h-1/2 sm:h-full">
                    <ActionMenu
                      buttonsData={fleeButtonsData}
                      size={"fill"}
                      title={buttonText}
                    />
                  </div>
                </div>
                <div className="hidden sm:flex flex-row gap-2 sm:flex-col items-center justify-center h-1/3 w-3/4">
                  <div className="flex flex-col items-center justify-center h-1/2 w-full">
                    <ActionMenu
                      buttonsData={attackButtonsData}
                      size={"fill"}
                      title="Attack"
                    />
                  </div>
                  <div className="flex flex-col items-center justify-center h-1/2 w-full">
                    <ActionMenu
                      buttonsData={fleeButtonsData}
                      size={"fill"}
                      title="Flee"
                    />
                  </div>
                </div>
              </>
            ) : (
              <div className="flex flex-col gap-5 items-center">
                <div className="flex flex-row gap-5">
                  <div className="flex flex-row items-center gap-2">
                    Current:
                    <div className="border border-terminal-green p-2">
                      <p className="animate-pulse">{currentBlockNumber}</p>
                    </div>
                  </div>
                  <div className="flex flex-row items-center gap-2">
                    Reveal:
                    <div className="border border-terminal-green p-2">
                      {adventurer?.revealBlock}
                    </div>
                  </div>
                </div>
                <p className="text-2xl loading-ellipsis">
                  Waiting for Block Reveal
                </p>
              </div>
            )}
          </>
        )}

        <div className="hidden sm:block h-2/3">
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
